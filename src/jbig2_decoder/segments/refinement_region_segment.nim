## Refinement Region Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../stream_decoder_types
import ./page_information_segment

type
  RefinementRegionSegment* = ref object of Segment
    ## Refinement region segment - improves an existing bitmap
    immediate*: bool
    refinementRegionFlags*: int
    referredToSegments*: seq[int]
    noOfReferredToSegments*: int
    regionBitmapWidth*: int
    regionBitmapHeight*: int
    regionBitmapXLocation*: int
    regionBitmapYLocation*: int
    regionFlags*: int
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef

proc newRefinementRegionSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, immediate: bool, referredToSegments: seq[int], noOfReferredToSegments: int, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): RefinementRegionSegment =
  ## Create a new refinement region segment
  result = RefinementRegionSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    immediate: immediate,
    referredToSegments: referredToSegments,
    noOfReferredToSegments: noOfReferredToSegments,
    refinementRegionFlags: 0,
    regionBitmapWidth: 0,
    regionBitmapHeight: 0,
    regionBitmapXLocation: 0,
    regionBitmapYLocation: 0,
    regionFlags: 0,
    reader: reader,
    streamDecoder: streamDecoder
  )

method readSegment*(segment: RefinementRegionSegment) =
  ## Read refinement region segment data
  ## Refinement regions improve an existing bitmap using arithmetic coding
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

  # Read refinement region flags (1 byte)
  segment.refinementRegionFlags = segment.reader.readByte().int

  let templateId = segment.refinementRegionFlags and 0x01

  # Read adaptive template values if template is 0
  var genericRegionAdaptiveTemplateX = @[0, 0]
  var genericRegionAdaptiveTemplateY = @[0, 0]
  if templateId == 0:
    genericRegionAdaptiveTemplateX[0] = cast[int8](segment.reader.readByte()).int
    genericRegionAdaptiveTemplateY[0] = cast[int8](segment.reader.readByte()).int
    genericRegionAdaptiveTemplateX[1] = cast[int8](segment.reader.readByte()).int
    genericRegionAdaptiveTemplateY[1] = cast[int8](segment.reader.readByte()).int

  # Check for too many referred segments
  if segment.noOfReferredToSegments > 1:
    # Debug: echo "Bad reference in JBIG2 generic refinement Segment"
    return

  # Get the referred bitmap
  var referredBitmap: JBIG2Bitmap = nil
  if segment.noOfReferredToSegments == 1 and segment.referredToSegments.len > 0:
    # Find the referred bitmap from segment number
    if segment.streamDecoder != nil:
      referredBitmap = segment.streamDecoder.findBitmap(segment.referredToSegments[0])
  elif segment.streamDecoder != nil:
    # Extract from page bitmap
    let pageSegment = segment.streamDecoder.findPageSegment(segment.segmentHeader.pageAssociation)
    if pageSegment != nil:
      let pageInfoSeg = cast[PageInformationSegment](pageSegment)
      if pageInfoSeg != nil:
        let pageBitmap = pageInfoSeg.pageBitmap
        if pageBitmap != nil:
          referredBitmap = pageBitmap.getSlice(segment.regionBitmapXLocation, segment.regionBitmapYLocation,
                                               segment.regionBitmapWidth, segment.regionBitmapHeight)

  if referredBitmap == nil:
    # Debug: echo "No referred bitmap found for refinement region"
    return

  # Reset refinement stats and start decoder
  segment.arithmeticDecoder.resetRefinementStats(templateId, nil)
  segment.arithmeticDecoder.start()

  let typicalPredictionGenericRefinementOn = ((segment.refinementRegionFlags shr 1) and 0x01) != 0

  # Create output bitmap and read refinement data
  let bitmap = newJBIG2Bitmap(segment.regionBitmapWidth, segment.regionBitmapHeight, 0)
  bitmap.readGenericRefinementRegion(segment.reader, segment.arithmeticDecoder, templateId,
                                     typicalPredictionGenericRefinementOn, referredBitmap, 0, 0,
                                     genericRegionAdaptiveTemplateX, genericRegionAdaptiveTemplateY)

  # Combine with page bitmap if inline, otherwise append as separate bitmap
  if segment.immediate and segment.streamDecoder != nil:
    let pageSegment = segment.streamDecoder.findPageSegment(segment.segmentHeader.pageAssociation)
    if pageSegment != nil:
      let pageInfoSeg = cast[PageInformationSegment](pageSegment)
      if pageInfoSeg != nil:
        let pageBitmap = pageInfoSeg.pageBitmap
        if pageBitmap != nil:
          let extCombOp = (segment.regionFlags shr 3) and 0x07
          pageBitmap.combine(bitmap, segment.regionBitmapXLocation, segment.regionBitmapYLocation, extCombOp)
  elif segment.streamDecoder != nil:
    bitmap.bitmapNumber = segment.segmentHeader.segmentNumber
    segment.streamDecoder.appendBitmap(bitmap)
