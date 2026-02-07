## Main JBIG2 stream decoder - Complete implementation based on C# reference
import ./jbig2_types
import ./jbig2_bitmap
import ./segment
import ./segment_header
import ./segment_factory
import ./stream_reader
import ./arithmetic_decoder
import ./huffman_decoder
import ./mmr_decoder
import ./binary_ops
import ./stream_decoder_types

type
  JBIG2StreamDecoderObj* = object
    reader*: Big2StreamReader
    arithmeticDecoder*: ArithmeticDecoder
    huffmanDecoder*: HuffmanDecoder
    mmrDecoder*: MMRDecoder
    noOfPagesKnown*: bool
    randomAccessOrganisation*: bool
    noOfPages*: int
    segments*: seq[Segment]
    bitmaps*: seq[JBIG2Bitmap]
    globalData*: seq[byte]
    debug*: bool

  JBIG2StreamDecoder* = ref JBIG2StreamDecoderObj

proc newJBIG2StreamDecoder*(): JBIG2StreamDecoder =
  ## Create a new JBIG2 stream decoder
  result = JBIG2StreamDecoder(
    noOfPagesKnown: false,
    randomAccessOrganisation: false,
    noOfPages: -1,
    segments: newSeq[Segment](),
    bitmaps: newSeq[JBIG2Bitmap](),
    debug: false
  )

proc movePointer*(decoder: JBIG2StreamDecoder, offset: int) =
  ## Move the stream pointer
  if decoder.reader != nil:
    decoder.reader.movePointer(offset)

proc setGlobalData*(decoder: JBIG2StreamDecoder, data: seq[byte]) =
  ## Set global data for the decoder
  decoder.globalData = data

proc getHuffmanDecoder*(decoder: JBIG2StreamDecoder): HuffmanDecoder =
  ## Get Huffman decoder
  result = decoder.huffmanDecoder

proc getMMRDecoder*(decoder: JBIG2StreamDecoder): MMRDecoder =
  ## Get MMR decoder
  result = decoder.mmrDecoder

proc getArithmeticDecoder*(decoder: JBIG2StreamDecoder): ArithmeticDecoder =
  ## Get arithmetic decoder
  result = decoder.arithmeticDecoder

proc resetDecoder*(decoder: JBIG2StreamDecoder) =
  ## Reset decoder state
  decoder.noOfPagesKnown = false
  decoder.randomAccessOrganisation = false
  decoder.noOfPages = -1
  decoder.segments = newSeq[Segment]()
  decoder.bitmaps = newSeq[JBIG2Bitmap]()

proc checkHeader*(decoder: JBIG2StreamDecoder): bool =
  ## Check if the stream starts with a valid JBIG2 header
  let controlHeader: seq[byte] = @[0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8, 0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8]
  var actualHeader = newSeq[byte](8)

  # Use the safe readByte that doesn't raise exceptions
  let readSuccess = decoder.reader.readByte(actualHeader)

  result = readSuccess and (controlHeader == actualHeader)

  if decoder.debug:
    echo "Header check: ", result

proc setFileHeaderFlags*(decoder: JBIG2StreamDecoder) =
  ## Parse and set file header flags
  let headerFlags = decoder.reader.readByte()

  # Check reserved bits (2-7) should be zero
  if (headerFlags and 0xFC) != 0:
    raise newException(InvalidHeaderValueError, "Reserved bits (2-7) of file header flags are not zero: " & $headerFlags)

  let fileOrganisation = headerFlags and 0x01
  decoder.randomAccessOrganisation = fileOrganisation == 0

  let pagesKnown = headerFlags and 0x02
  decoder.noOfPagesKnown = pagesKnown == 0

  if decoder.debug:
    echo "File header flags: ", headerFlags
    echo "randomAccessOrganisation: ", decoder.randomAccessOrganisation
    echo "noOfPagesKnown: ", decoder.noOfPagesKnown

proc getNoOfPages*(decoder: JBIG2StreamDecoder): int =
  ## Get number of pages from file header
  if decoder.noOfPagesKnown:
    var noOfPagesBytes = newSeq[byte](4)
    for i in 0..<4:
      noOfPagesBytes[i] = decoder.reader.readByte()
    result = getInt32(noOfPagesBytes).int
    # Validate number of pages - cannot be negative
    if result < 0:
      raise newException(InvalidHeaderValueError, "Number of pages cannot be negative: " & $result)
    # Check for potential integer overflow (more than reasonable number of pages)
    if result > 0x7FFFFFFF:
      raise newException(IntegerMaxValueError, "Number of pages exceeds maximum allowed value: " & $result)
  else:
    result = -1

proc handleSegmentNumber*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Read and set segment number
  var segmentBytes = newSeq[byte](4)
  for i in 0..<4:
    segmentBytes[i] = decoder.reader.readByte()
  header.segmentNumber = getInt32(segmentBytes).int

  # Validate segment number - cannot be negative
  if header.segmentNumber < 0:
    raise newException(InvalidHeaderValueError, "Segment number cannot be negative: " & $header.segmentNumber)

  if decoder.debug:
    echo "Segment number: ", header.segmentNumber

proc handleSegmentHeaderFlags*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Read and parse segment header flags
  let segmentHeaderFlags = decoder.reader.readByte()
  header.setSegmentHeaderFlags(segmentHeaderFlags)

  # Validate segment type - must be a valid value (0-51 are valid, 52-63 are reserved)
  if header.segmentType > 63:
    raise newException(InvalidHeaderValueError, "Invalid segment type: " & $header.segmentType)

  if decoder.debug:
    echo "Segment type: ", header.segmentType

proc handleSegmentReferredToCountAndRetentionFlags*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Handle referred-to segment count and retention flags
  let referredToSegmentCountAndRetentionFlags = decoder.reader.readByte()

  let referredToSegmentCount = (referredToSegmentCountAndRetentionFlags and 0xE0) shr 5
  let firstByte = referredToSegmentCountAndRetentionFlags and 0x1F

  var retentionFlags: seq[byte]

  if referredToSegmentCount <= 4:
    # Short form
    retentionFlags = newSeq[byte](1)
    retentionFlags[0] = firstByte
    header.referredToSegmentCount = referredToSegmentCount.int
  elif referredToSegmentCount == 7:
    # Long form
    var longFormCountAndFlags = newSeq[byte](4)
    longFormCountAndFlags[0] = firstByte

    for i in 1..<4:
      longFormCountAndFlags[i] = decoder.reader.readByte()

    let actualReferredToSegmentCount = getInt32(longFormCountAndFlags).int

    let noOfbytesInField = int(4 + ((actualReferredToSegmentCount + 1) div 8))
    let noOfRetentionFlagBytes = noOfbytesInField - 4

    retentionFlags = newSeq[byte](noOfRetentionFlagBytes)
    for i in 0..<noOfRetentionFlagBytes:
      retentionFlags[i] = decoder.reader.readByte()

    header.referredToSegmentCount = actualReferredToSegmentCount
  else:
    # Error case
    header.referredToSegmentCount = referredToSegmentCount.int

  header.retentionFlags = retentionFlags

  if decoder.debug:
    echo "referredToSegmentCount: ", header.referredToSegmentCount

proc handleReferredToSegmentNumbers*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Handle referred-to segment numbers
  let referredToSegmentCount = header.referredToSegmentCount
  var referredToSegments = newSeq[int](referredToSegmentCount)

  let segmentNumber = header.segmentNumber

  if segmentNumber <= 256:
    for i in 0..<referredToSegmentCount:
      referredToSegments[i] = decoder.reader.readByte().int
  elif segmentNumber <= 65536:
    for i in 0..<referredToSegmentCount:
      var buf = newSeq[byte](2)
      for j in 0..<2:
        buf[j] = decoder.reader.readByte()
      referredToSegments[i] = getInt16(buf).int
  else:
    for i in 0..<referredToSegmentCount:
      var buf = newSeq[byte](4)
      for j in 0..<4:
        buf[j] = decoder.reader.readByte()
      referredToSegments[i] = getInt32(buf).int

  header.referredToSegments = referredToSegments

  if decoder.debug:
    echo "referredToSegments: ", referredToSegments

proc handlePageAssociation*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Handle page association
  var pageAssociation: int

  if header.pageAssociationSizeSet:
    # Field is 4 bytes long
    var buf = newSeq[byte](4)
    for i in 0..<4:
      buf[i] = decoder.reader.readByte()
    pageAssociation = getInt32(buf).int
  else:
    # Field is 1 byte long
    pageAssociation = decoder.reader.readByte().int

  header.pageAssociation = pageAssociation

  if decoder.debug:
    echo "pageAssociation: ", pageAssociation

proc handleSegmentDataLength*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Handle segment data length
  var buf = newSeq[byte](4)
  for i in 0..<4:
    buf[i] = decoder.reader.readByte()

  let dataLength = getInt32(buf).int

  # Validate data length - cannot be negative
  if dataLength < 0:
    raise newException(InvalidHeaderValueError, "Segment data length cannot be negative: " & $dataLength)

  # Check for potential integer overflow
  if dataLength > 0x7FFFFFFF:
    raise newException(IntegerMaxValueError, "Segment data length exceeds maximum allowed value: " & $dataLength)

  header.dataLength = dataLength

  if decoder.debug:
    echo "dataLength: ", header.dataLength

proc readSegmentHeader*(decoder: JBIG2StreamDecoder, header: SegmentHeader) =
  ## Read complete segment header
  decoder.handleSegmentNumber(header)
  decoder.handleSegmentHeaderFlags(header)
  decoder.handleSegmentReferredToCountAndRetentionFlags(header)
  decoder.handleReferredToSegmentNumbers(header)
  decoder.handlePageAssociation(header)

  if header.segmentType != SEG_END_OF_FILE:
    decoder.handleSegmentDataLength(header)

proc readBits*(decoder: JBIG2StreamDecoder, num: int): int =
  ## Read bits from stream
  result = decoder.reader.readBits(num)

proc readBit*(decoder: JBIG2StreamDecoder): int =
  ## Read a single bit from stream
  result = decoder.reader.readBit()

proc readByte*(decoder: JBIG2StreamDecoder): byte =
  ## Read a single byte from stream
  result = decoder.reader.readByte()

proc readBytes*(decoder: JBIG2StreamDecoder, buf: var seq[byte]) =
  ## Read multiple bytes into buffer
  for i in 0..<buf.len:
    buf[i] = decoder.reader.readByte()

proc consumeRemainingBits*(decoder: JBIG2StreamDecoder) =
  ## Consume remaining bits in current byte
  decoder.reader.consumeRemainingBits()

proc appendBitmap*(decoder: JBIG2StreamDecoder, bitmap: JBIG2Bitmap) =
  ## Append bitmap to decoder's bitmap list
  decoder.bitmaps.add(bitmap)

proc findBitmap*(decoder: JBIG2StreamDecoder, bitmapNumber: int): JBIG2Bitmap =
  ## Find bitmap by number
  for bitmap in decoder.bitmaps:
    if bitmap.bitmapNumber == bitmapNumber:
      return bitmap
  result = nil

proc findPageSegment*(decoder: JBIG2StreamDecoder, page: int): Segment =
  ## Find page information segment for given page number
  for segment in decoder.segments:
    let header = segment.getSegmentHeader()
    if header.segmentType == SEG_PAGE_INFORMATION and header.pageAssociation == page:
      return segment
  result = nil

proc findFirstPageSegment*(decoder: JBIG2StreamDecoder): Segment =
  ## Find first page information segment
  for segment in decoder.segments:
    let header = segment.getSegmentHeader()
    if header.segmentType == SEG_PAGE_INFORMATION:
      return segment
  result = nil

proc getPageAsJBIG2Bitmap*(decoder: JBIG2StreamDecoder, page: int): JBIG2Bitmap =
  ## Get the bitmap for a specific page
  ## Returns nil if no page bitmap is found
  # First check if we have any bitmaps in the decoder
  if decoder.bitmaps.len > 0:
    return decoder.bitmaps[0]

  # Try to find a PageInformationSegment and get its bitmap
  let pageSegment = decoder.findFirstPageSegment()
  if pageSegment != nil:
    # Cast to PageInformationSegment to access pageBitmap
    let pageInfoSegment = cast[PageInformationSegment](pageSegment)
    if pageInfoSegment != nil:
      return pageInfoSegment.getPageBitmap()

  result = nil

proc findSegment*(decoder: JBIG2StreamDecoder, segmentNumber: int): Segment =
  ## Find segment by segment number
  for segment in decoder.segments:
    if segment.getSegmentHeader().segmentNumber == segmentNumber:
      return segment
  result = nil

proc readSegments*(decoder: JBIG2StreamDecoder) =
  ## Read all segments from the stream
  var finished = false

  while not decoder.reader.isFinished() and not finished:
    var segmentHeader = newSegmentHeader()
    decoder.readSegmentHeader(segmentHeader)

    # Read the segment data
    var segment: Segment = nil

    let segmentType = segmentHeader.segmentType
    discard segmentHeader.referredToSegments  # used via segment.setSegmentHeader
    discard segmentHeader.referredToSegmentCount  # used via segment.setSegmentHeader

    # Cast decoder to JBIG2StreamDecoderRef for passing to segments
    let streamDecoderRef = cast[JBIG2StreamDecoderRef](decoder)

    case segmentType
    of SEG_SYMBOL_DICTIONARY:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_INTERMEDIATE_TEXT_REGION, SEG_IMMEDIATE_TEXT_REGION, SEG_IMMEDIATE_LOSSLESS_TEXT_REGION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_PATTERN_DICTIONARY:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_INTERMEDIATE_HALFTONE_REGION, SEG_IMMEDIATE_HALFTONE_REGION, SEG_IMMEDIATE_LOSSLESS_HALFTONE_REGION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_INTERMEDIATE_GENERIC_REGION, SEG_IMMEDIATE_GENERIC_REGION, SEG_IMMEDIATE_LOSSLESS_GENERIC_REGION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_INTERMEDIATE_GENERIC_REFINEMENT_REGION, SEG_IMMEDIATE_GENERIC_REFINEMENT_REGION, SEG_IMMEDIATE_LOSSLESS_GENERIC_REFINEMENT_REGION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_PAGE_INFORMATION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_END_OF_PAGE:
      # Skip segment data for END_OF_PAGE (dataLength should be 0, but skip just in case)
      decoder.reader.movePointer(segmentHeader.dataLength)
      continue
    of SEG_END_OF_STRIPE:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    of SEG_END_OF_FILE:
      finished = true
      continue
    of SEG_PROFILES, SEG_TABLES:
      # Not implemented yet - skip segment data
      decoder.reader.movePointer(segmentHeader.dataLength)
    of SEG_EXTENSION:
      segment = createSegment(segmentType, decoder.huffmanDecoder, decoder.arithmeticDecoder, decoder.mmrDecoder, decoder.reader, streamDecoderRef)
      segment.setSegmentHeader(segmentHeader)
    else:
      # Unknown segment type - skip segment data to avoid infinite loop
      decoder.reader.movePointer(segmentHeader.dataLength)

    if segment != nil:
      # Record position before reading segment data
      let segmentDataStart = decoder.reader.position
      let dataLength = segmentHeader.dataLength

      if not decoder.randomAccessOrganisation:
        segment.readSegment()

      # Skip any remaining bytes in the segment data to align with next segment
      if dataLength > 0:
        let bytesRead = decoder.reader.position - segmentDataStart
        let remainingBytes = dataLength - bytesRead
        if remainingBytes > 0:
          decoder.reader.movePointer(remainingBytes)

      decoder.segments.add(segment)

  # If random access organization, read segments after all headers are parsed
  if decoder.randomAccessOrganisation:
    for segment in decoder.segments:
      segment.readSegment()

proc decodeJBIG2*(decoder: JBIG2StreamDecoder, data: seq[byte], format: ImageFormat = TIFF, newWidth: int = 0, newHeight: int = 0): seq[byte] =
  ## Decode JBIG2 compressed image data
  # Handle empty data gracefully
  if data.len == 0:
    return newSeq[byte]()

  decoder.reader = newBig2StreamReader(data)
  decoder.resetDecoder()

  let validFile = decoder.checkHeader()

  if decoder.debug:
    echo "validFile = ", validFile

  if not validFile:
    # Assume this is a stream from a PDF so there is no file header
    decoder.noOfPagesKnown = true
    decoder.randomAccessOrganisation = false
    decoder.noOfPages = 1

    # Check to see if there is any global data to be read
    if decoder.globalData.len > 0:
      # Set the reader to read from the global data
      decoder.reader = newBig2StreamReader(decoder.globalData)

      decoder.huffmanDecoder = newHuffmanDecoder(decoder.reader)
      decoder.mmrDecoder = newMMRDecoder(decoder.reader)
      decoder.arithmeticDecoder = newArithmeticDecoder(decoder.reader)

      # Read in the global data segments
      decoder.readSegments()

      # Set the reader back to the main data
      decoder.reader = newBig2StreamReader(data)
    else:
      # There's no global data, so move the file pointer back to the start of the stream
      decoder.reader.movePointer(-8)
      # If data is too small to be a valid JBIG2 stream, return empty result
      if data.len < 11:  # Minimum segment header size
        return newSeq[byte]()
  else:
    # We have the file header, so assume it is a valid stand-alone file
    if decoder.debug:
      echo "==== File Header ===="

    decoder.setFileHeaderFlags()

    if decoder.debug:
      echo "randomAccessOrganisation = ", decoder.randomAccessOrganisation
      echo "noOfPagesKnown = ", decoder.noOfPagesKnown

    if decoder.noOfPagesKnown:
      decoder.noOfPages = decoder.getNoOfPages()
      if decoder.debug:
        echo "noOfPages = ", decoder.noOfPages

  decoder.huffmanDecoder = newHuffmanDecoder(decoder.reader)
  decoder.mmrDecoder = newMMRDecoder(decoder.reader)
  decoder.arithmeticDecoder = newArithmeticDecoder(decoder.reader)

  # Read in the main segment data
  decoder.readSegments()

  # Create image from decoded segments
  # Get the page bitmap and convert to output format
  let pageBitmap = decoder.getPageAsJBIG2Bitmap(1)

  if pageBitmap != nil:
    # Get the raw bitmap data with pixel color switched (matching C# implementation)
    result = pageBitmap.getData(true)
  else:
    result = newSeq[byte]()
