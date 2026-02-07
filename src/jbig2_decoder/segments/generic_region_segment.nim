## Generic Region Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../stream_decoder_types

type

  GenericRegionSegment* = ref object of Segment
    ## Generic region segment
    immediate*: bool
    genericRegionFlags*: int
    regionBitmapWidth*: int
    regionBitmapHeight*: int
    regionBitmapXLocation*: int
    regionBitmapYLocation*: int
    regionFlags*: int
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef

proc newGenericRegionSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, immediate: bool, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): GenericRegionSegment =
  ## Create a new generic region segment
  result = GenericRegionSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    immediate: immediate,
    genericRegionFlags: 0,
    regionBitmapWidth: 0,
    regionBitmapHeight: 0,
    regionBitmapXLocation: 0,
    regionBitmapYLocation: 0,
    regionFlags: 0,
    reader: reader,
    streamDecoder: streamDecoder
  )

method readSegment*(segment: GenericRegionSegment) =
  ## Read generic region segment data
  if segment.reader == nil:
    return

  # Read region segment data
  var buff = newSeq[byte](4)

  # Read region bitmap width
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.regionBitmapWidth = getInt32(buff).int

  # Read region bitmap height
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.regionBitmapHeight = getInt32(buff).int

  # Read region bitmap X location
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.regionBitmapXLocation = getInt32(buff).int

  # Read region bitmap Y location
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.regionBitmapYLocation = getInt32(buff).int

  # Read region flags
  segment.regionFlags = segment.reader.readByte().int

  # Read generic region flags (1 byte)
  segment.genericRegionFlags = segment.reader.readByte().int

  let useMMR = (segment.genericRegionFlags and 0x01) != 0
  let gbTemplate = (segment.genericRegionFlags shr 1) and 0x03
  let tpgdon = ((segment.genericRegionFlags shr 3) and 0x01) != 0

  # Read adaptive template values if not using MMR
  var adaptiveTemplateX: array[4, int]
  var adaptiveTemplateY: array[4, int]

  if not useMMR:
    if gbTemplate == 0:
      # Read 4 pairs of adaptive template values
      for i in 0..<4:
        adaptiveTemplateX[i] = cast[int8](segment.reader.readByte()).int
        adaptiveTemplateY[i] = cast[int8](segment.reader.readByte()).int
    else:
      # Read 1 pair of adaptive template values
      adaptiveTemplateX[0] = cast[int8](segment.reader.readByte()).int
      adaptiveTemplateY[0] = cast[int8](segment.reader.readByte()).int

    # Reset and start arithmetic decoder
    if segment.arithmeticDecoder != nil:
      segment.arithmeticDecoder.resetGenericStats(gbTemplate, nil)
      segment.arithmeticDecoder.start()

  # Determine data length
  var dataLength = -1  # Unknown length
  var unknownLength = false

  # Check if segment data length is known from header
  if segment.segmentHeader != nil:
    dataLength = segment.segmentHeader.dataLength

  if dataLength == -1:
    # Length unknown - need to determine from data
    unknownLength = true

    var match1, match2: int
    if useMMR:
      match1 = 0
      match2 = 0
    else:
      match1 = 255
      match2 = 172

    var bytesRead = 0
    while true:
      let bite1 = segment.reader.readByte().int
      bytesRead += 1

      if bite1 == match1:
        let bite2 = segment.reader.readByte().int
        bytesRead += 1

        if bite2 == match2:
          dataLength = bytesRead - 2
          break

    # Move pointer back to start of data
    segment.reader.movePointer(-bytesRead)

  # Create bitmap and decode
  var bitmap = newJBIG2Bitmap(segment.regionBitmapWidth, segment.regionBitmapHeight, 0)
  bitmap.clear(0)

  if useMMR:
    # MMR decoding
    let mmrDataLength = if dataLength >= 0: dataLength else: -1
    bitmap.readBitmapMMR(segment.reader, segment.mmrDecoder, mmrDataLength)
  else:
    # Arithmetic decoding
    let mmrDataLength = if dataLength >= 0: dataLength - 18 else: -1
    bitmap.readBitmapArithmetic(segment.reader, segment.arithmeticDecoder, gbTemplate, tpgdon, adaptiveTemplateX, adaptiveTemplateY)

  # Handle inline image or append to decoder
  # Note: streamDecoder operations would need to be handled by the caller
  # to avoid circular dependencies

  # Skip past end marker if unknown length
  if unknownLength:
    segment.reader.movePointer(4)
