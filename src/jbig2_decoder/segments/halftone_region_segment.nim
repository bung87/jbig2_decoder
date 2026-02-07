## Halftone Region Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../stream_decoder_types
import ./pattern_dictionary_segment
import ./page_information_segment

type
  HalftoneRegionSegment* = ref object of Segment
    ## Halftone region segment - renders grayscale using patterns
    immediate*: bool
    halftoneRegionFlags*: int
    regionBitmapWidth*: int
    regionBitmapHeight*: int
    regionBitmapXLocation*: int
    regionBitmapYLocation*: int
    regionFlags*: int
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef

proc newHalftoneRegionSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, immediate: bool, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): HalftoneRegionSegment =
  ## Create a new halftone region segment
  result = HalftoneRegionSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    immediate: immediate,
    halftoneRegionFlags: 0,
    regionBitmapWidth: 0,
    regionBitmapHeight: 0,
    regionBitmapXLocation: 0,
    regionBitmapYLocation: 0,
    regionFlags: 0,
    reader: reader,
    streamDecoder: streamDecoder
  )

method readSegment*(segment: HalftoneRegionSegment) =
  ## Read halftone region segment data
  ## Halftone regions use patterns to simulate grayscale images
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

  # Read halftone region flags (2 bytes)
  buff = newSeq[byte](2)
  for i in 0..<2:
    buff[i] = segment.reader.readByte()
  segment.halftoneRegionFlags = getInt16(buff).int

  # Read grid width (4 bytes)
  buff = newSeq[byte](4)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  let gridWidth = getInt32(buff).int

  # Read grid height (4 bytes)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  let gridHeight = getInt32(buff).int

  # Read grid origin X (4 bytes)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  let gridX = getInt32(buff).int

  # Read grid origin Y (4 bytes)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  let gridY = getInt32(buff).int

  # Read step size X and Y (2 bytes each)
  buff = newSeq[byte](2)
  for i in 0..<2:
    buff[i] = segment.reader.readByte()
  let stepX = getInt16(buff).int

  for i in 0..<2:
    buff[i] = segment.reader.readByte()
  let stepY = getInt16(buff).int

  # Get referred pattern dictionary segment
  if segment.segmentHeader == nil or segment.segmentHeader.referredToSegments.len != 1:
    return

  if segment.streamDecoder == nil:
    return

  let referredSeg = segment.streamDecoder.findSegment(segment.segmentHeader.referredToSegments[0])
  if referredSeg == nil:
    return

  # Check if it's a pattern dictionary
  let patternDictSeg = cast[PatternDictionarySegment](referredSeg)
  if patternDictSeg == nil:
    return

  # Calculate bits per value
  let patternSize = patternDictSeg.getSize()
  var bitsPerValue = 0
  var i = 1
  while i < patternSize:
    bitsPerValue += 1
    i = i shl 1

  # Get pattern dimensions
  let firstPattern = patternDictSeg.getBitmaps()[0]
  let patternWidth = firstPattern.width
  let patternHeight = firstPattern.height

  # Extract flags
  let useMMR = (segment.halftoneRegionFlags and 0x01) != 0
  let templateId = (segment.halftoneRegionFlags shr 1) and 0x03
  let halftoneDefaultPixel = (segment.halftoneRegionFlags shr 3) and 0x01
  let enableSkip = ((segment.halftoneRegionFlags shr 4) and 0x01) != 0
  let combinationOperator = (segment.halftoneRegionFlags shr 5) and 0x03

  # Reset arithmetic decoder if not using MMR
  if not useMMR:
    segment.arithmeticDecoder.resetGenericStats(templateId, nil)
    segment.arithmeticDecoder.start()

  # Create output bitmap
  let bitmap = newJBIG2Bitmap(segment.regionBitmapWidth, segment.regionBitmapHeight, 0)
  bitmap.clear(halftoneDefaultPixel)

  # Create skip bitmap if enabled
  var skipBitmap: JBIG2Bitmap = nil
  if enableSkip:
    skipBitmap = newJBIG2Bitmap(gridWidth, gridHeight, 0)
    skipBitmap.clear(0)
    for y in 0..<gridHeight:
      for x in 0..<gridWidth:
        let xx = gridX + y * stepY + x * stepX
        let yy = gridY + y * stepX - x * stepY
        if ((xx + patternWidth) shr 8) <= 0 or (xx shr 8) >= segment.regionBitmapWidth or
           ((yy + patternHeight) shr 8) <= 0 or (yy shr 8) >= segment.regionBitmapHeight:
          skipBitmap.setPixel(x, y, 1)

  # Initialize grayscale image array
  var grayScaleImage = newSeq[int](gridWidth * gridHeight)

  # Set up adaptive template
  var genericBAdaptiveTemplateX = @[(if templateId <= 1: 3 else: 2), -3, 2, -2]
  var genericBAdaptiveTemplateY = @[-1, -1, -2, -2]

  # Decode grayscale values bit plane by bit plane
  for j in countdown(bitsPerValue - 1, 0):
    let grayBitmap = newJBIG2Bitmap(gridWidth, gridHeight, 0)
    if useMMR:
      grayBitmap.readBitmapMMR(segment.reader, segment.mmrDecoder, -1)
    else:
      grayBitmap.readBitmapArithmetic(segment.reader, segment.arithmeticDecoder, templateId, false,
                                      genericBAdaptiveTemplateX, genericBAdaptiveTemplateY)

    var idx = 0
    for row in 0..<gridHeight:
      for col in 0..<gridWidth:
        let bit = grayBitmap.getPixel(col, row) xor (grayScaleImage[idx] and 1)
        grayScaleImage[idx] = (grayScaleImage[idx] shl 1) or bit
        idx += 1

  # Render patterns to output bitmap
  var idx = 0
  for col in 0..<gridHeight:
    var xx = gridX + col * stepY
    var yy = gridY + col * stepX
    for row in 0..<gridWidth:
      if not (enableSkip and skipBitmap.getPixel(row, col) == 1):
        let patternIdx = grayScaleImage[idx]
        if patternIdx < patternDictSeg.bitmaps.len:
          let patternBitmap = patternDictSeg.bitmaps[patternIdx]
          bitmap.combine(patternBitmap, xx shr 8, yy shr 8, combinationOperator)

      xx += stepX
      yy -= stepY
      idx += 1

  # Combine with page bitmap if inline, otherwise append as separate bitmap
  if segment.immediate:
    let pageSegment = segment.streamDecoder.findPageSegment(segment.segmentHeader.pageAssociation)
    if pageSegment != nil:
      let pageInfoSeg = cast[PageInformationSegment](pageSegment)
      if pageInfoSeg != nil:
        let pageBitmap = pageInfoSeg.pageBitmap
        if pageBitmap != nil:
          let externalCombinationOperator = (segment.regionFlags shr 3) and 0x07
          pageBitmap.combine(bitmap, segment.regionBitmapXLocation, segment.regionBitmapYLocation, externalCombinationOperator)
  else:
    bitmap.bitmapNumber = segment.segmentHeader.segmentNumber
    segment.streamDecoder.appendBitmap(bitmap)
