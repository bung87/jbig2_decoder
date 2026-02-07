## Text Region Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../stream_decoder_types
import ./symbol_dictionary_segment
import ./page_information_segment

type
  TextRegionSegment* = ref object of Segment
    ## Text region segment - places symbols to form text
    immediate*: bool
    textRegionFlags*: int
    textRegionHuffmanFlags*: int
    regionBitmapWidth*: int
    regionBitmapHeight*: int
    regionBitmapXLocation*: int
    regionBitmapYLocation*: int
    regionFlags*: int
    symbolRegionAdaptiveTemplateX*: array[2, int16]
    symbolRegionAdaptiveTemplateY*: array[2, int16]
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef

proc newTextRegionSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, immediate: bool, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): TextRegionSegment =
  ## Create a new text region segment
  result = TextRegionSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    immediate: immediate,
    textRegionFlags: 0,
    textRegionHuffmanFlags: 0,
    regionBitmapWidth: 0,
    regionBitmapHeight: 0,
    regionBitmapXLocation: 0,
    regionBitmapYLocation: 0,
    regionFlags: 0,
    symbolRegionAdaptiveTemplateX: [0.int16, 0],
    symbolRegionAdaptiveTemplateY: [0.int16, 0],
    reader: reader,
    streamDecoder: streamDecoder
  )

method readSegment*(segment: TextRegionSegment) =
  ## Read text region segment data
  ## Text regions place symbols from dictionaries to form text
  if segment.reader == nil:
    return

  # Read region segment data (width, height, location, flags)
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

  # Read text region flags (2 bytes)
  buff = newSeq[byte](2)
  for i in 0..<2:
    buff[i] = segment.reader.readByte()
  segment.textRegionFlags = getInt16(buff).int

  # Extract key flags
  let sbHuff = (segment.textRegionFlags and 0x01) != 0
  let sbRefine = ((segment.textRegionFlags shr 1) and 0x01) != 0
  let sbrTemplate = ((segment.textRegionFlags shr 10) and 0x01)
  let defaultPixel = ((segment.textRegionFlags shr 4) and 0x01)
  let combinationOperator = ((segment.textRegionFlags shr 5) and 0x03)
  let transposed = ((segment.textRegionFlags shr 6) and 0x01) != 0
  let referenceCorner = ((segment.textRegionFlags shr 7) and 0x03)
  let sOffset = cast[int8]((segment.textRegionFlags shr 9) and 0x03)
  let logStrips = ((segment.textRegionFlags shr 11) and 0x03)

  # Read text region Huffman flags if using Huffman encoding
  if sbHuff:
    for i in 0..<2:
      buff[i] = segment.reader.readByte()
    segment.textRegionHuffmanFlags = getInt16(buff).int

  # Read adaptive template values if refinement is enabled and template is 0
  if sbRefine and sbrTemplate == 0:
    segment.symbolRegionAdaptiveTemplateX[0] = cast[int8](segment.reader.readByte())
    segment.symbolRegionAdaptiveTemplateY[0] = cast[int8](segment.reader.readByte())
    segment.symbolRegionAdaptiveTemplateX[1] = cast[int8](segment.reader.readByte())
    segment.symbolRegionAdaptiveTemplateY[1] = cast[int8](segment.reader.readByte())

  # Read number of symbol instances (4 bytes)
  buff = newSeq[byte](4)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  let noOfSymbolInstances = getInt32(buff).int

  # Collect symbols from referred symbol dictionary segments
  var symbols: seq[JBIG2Bitmap] = @[]
  var noOfSymbols = 0

  if segment.segmentHeader != nil and segment.streamDecoder != nil:
    let referredToSegments = segment.segmentHeader.referredToSegments

    for segNum in referredToSegments:
      let seg = segment.streamDecoder.findSegment(segNum)
      if seg == nil:
        continue

      # Check if it's a symbol dictionary segment
      let symDictSeg = cast[SymbolDictionarySegment](seg)
      if symDictSeg != nil and symDictSeg.bitmaps.len > 0:
        for bitmap in symDictSeg.bitmaps:
          symbols.add(bitmap)
          noOfSymbols += 1

  if noOfSymbols == 0:
    return

  # Calculate symbol code length
  var symbolCodeLength = 0
  var count = 1
  while count < noOfSymbols:
    symbolCodeLength += 1
    count = count shl 1

  # Set up Huffman tables if using Huffman encoding
  var huffmanFSTable: seq[seq[int64]] = @[]
  var huffmanDSTable: seq[seq[int64]] = @[]
  var huffmanDTTable: seq[seq[int64]] = @[]
  var huffmanRDWTable: seq[seq[int64]] = @[]
  var huffmanRDHTable: seq[seq[int64]] = @[]
  var huffmanRDXTable: seq[seq[int64]] = @[]
  var huffmanRDYTable: seq[seq[int64]] = @[]
  var huffmanRSizeTable: seq[seq[int64]] = @[]

  if sbHuff:
    # Decode Huffman flags and select appropriate tables
    let sbHuffFS = (segment.textRegionHuffmanFlags shr 0) and 0x03
    let sbHuffDS = (segment.textRegionHuffmanFlags shr 2) and 0x03
    let sbHuffDT = (segment.textRegionHuffmanFlags shr 4) and 0x03
    let sbHuffRDW = (segment.textRegionHuffmanFlags shr 6) and 0x03
    let sbHuffRDH = (segment.textRegionHuffmanFlags shr 8) and 0x03
    let sbHuffRDX = (segment.textRegionHuffmanFlags shr 10) and 0x03
    let sbHuffRDY = (segment.textRegionHuffmanFlags shr 12) and 0x03
    let sbHuffRSize = (segment.textRegionHuffmanFlags shr 14) and 0x01

    # Select FS table
    case sbHuffFS
    of 0: huffmanFSTable = huffmanTableF
    of 1: huffmanFSTable = huffmanTableG
    else: discard

    # Select DS table
    case sbHuffDS
    of 0: huffmanDSTable = huffmanTableH
    of 1: huffmanDSTable = huffmanTableI
    of 2: huffmanDSTable = huffmanTableJ
    else: discard

    # Select DT table
    case sbHuffDT
    of 0: huffmanDTTable = huffmanTableK
    of 1: huffmanDTTable = huffmanTableL
    of 2: huffmanDTTable = huffmanTableM
    else: discard

    # Select RDW/RDH/RDX/RDY tables
    case sbHuffRDW
    of 0: huffmanRDWTable = huffmanTableN
    of 1: huffmanRDWTable = huffmanTableO
    else: discard

    case sbHuffRDH
    of 0: huffmanRDHTable = huffmanTableN
    of 1: huffmanRDHTable = huffmanTableO
    else: discard

    case sbHuffRDX
    of 0: huffmanRDXTable = huffmanTableN
    of 1: huffmanRDXTable = huffmanTableO
    else: discard

    case sbHuffRDY
    of 0: huffmanRDYTable = huffmanTableN
    of 1: huffmanRDYTable = huffmanTableO
    else: discard

    # Select RSize table
    if sbHuffRSize == 0:
      huffmanRSizeTable = huffmanTableA

  # Reset arithmetic decoder if not using Huffman
  if not sbHuff:
    segment.arithmeticDecoder.resetIntStats(symbolCodeLength)
    segment.arithmeticDecoder.start()

  # Reset refinement stats if symbol refinement is enabled
  if sbRefine:
    segment.arithmeticDecoder.resetRefinementStats(sbrTemplate, nil)

  # Create output bitmap
  let bitmap = newJBIG2Bitmap(segment.regionBitmapWidth, segment.regionBitmapHeight, 0)
  bitmap.clear(defaultPixel)

  let strips = 1 shl logStrips

  # Decode text region data
  var t: int
  if sbHuff:
    t = segment.huffmanDecoder.decodeInt(huffmanDTTable).value.int
  else:
    t = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iadtStats).value
  t *= -strips

  var currentInstance = 0
  var firstS = 0
  var dt, tt, ds, s: int

  while currentInstance < noOfSymbolInstances:
    # Decode delta T
    if sbHuff:
      dt = segment.huffmanDecoder.decodeInt(huffmanDTTable).value.int
    else:
      dt = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iadtStats).value
    t += dt * strips

    # Decode first S
    if sbHuff:
      ds = segment.huffmanDecoder.decodeInt(huffmanFSTable).value.int
    else:
      ds = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iafsStats).value
    firstS += ds
    s = firstS

    # Process symbols in strip
    while true:
      # Decode delta T for this instance
      if strips == 1:
        dt = 0
      elif sbHuff:
        dt = segment.streamDecoder.reader.readBits(logStrips).int
      else:
        dt = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iaitStats).value
      tt = t + dt

      # Decode symbol ID
      var symbolID: int
      if sbHuff:
        # For Huffman, symbol ID is read directly
        symbolID = segment.streamDecoder.reader.readBits(symbolCodeLength).int
      else:
        symbolID = segment.arithmeticDecoder.decodeIAID(symbolCodeLength, segment.arithmeticDecoder.iaidStats).int

      if symbolID < noOfSymbols:
        var symbolBitmap: JBIG2Bitmap = nil

        # Check if refinement is needed
        var ri: int
        if sbRefine:
          if sbHuff:
            ri = segment.streamDecoder.reader.readBit().int
          else:
            ri = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iariStats).value
        else:
          ri = 0

        if ri != 0:
          # Decode refinement parameters
          var refinementDeltaWidth, refinementDeltaHeight, refinementDeltaX, refinementDeltaY: int

          if sbHuff:
            refinementDeltaWidth = segment.huffmanDecoder.decodeInt(huffmanRDWTable).value.int
            refinementDeltaHeight = segment.huffmanDecoder.decodeInt(huffmanRDHTable).value.int
            refinementDeltaX = segment.huffmanDecoder.decodeInt(huffmanRDXTable).value.int
            refinementDeltaY = segment.huffmanDecoder.decodeInt(huffmanRDYTable).value.int

            segment.streamDecoder.consumeRemainingBits()
            segment.arithmeticDecoder.start()
          else:
            refinementDeltaWidth = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardwStats).value
            refinementDeltaHeight = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardhStats).value
            refinementDeltaX = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardxStats).value
            refinementDeltaY = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardyStats).value

          refinementDeltaX = ((if refinementDeltaWidth >= 0: refinementDeltaWidth else: refinementDeltaWidth - 1) div 2) + refinementDeltaX
          refinementDeltaY = ((if refinementDeltaHeight >= 0: refinementDeltaHeight else: refinementDeltaHeight - 1) div 2) + refinementDeltaY

          # Create refined bitmap
          let baseSymbol = symbols[symbolID]
          symbolBitmap = newJBIG2Bitmap(refinementDeltaWidth + baseSymbol.width, refinementDeltaHeight + baseSymbol.height, 0)

          let adaptiveTemplateX = @[segment.symbolRegionAdaptiveTemplateX[0].int, segment.symbolRegionAdaptiveTemplateX[1].int]
          let adaptiveTemplateY = @[segment.symbolRegionAdaptiveTemplateY[0].int, segment.symbolRegionAdaptiveTemplateY[1].int]
          symbolBitmap.readGenericRefinementRegion(segment.reader, segment.arithmeticDecoder, sbrTemplate,
                                                   false, baseSymbol, refinementDeltaX, refinementDeltaY,
                                                   adaptiveTemplateX, adaptiveTemplateY)
        else:
          symbolBitmap = symbols[symbolID]

        # Place symbol on bitmap
        let bitmapWidth = symbolBitmap.width - 1
        let bitmapHeight = symbolBitmap.height - 1

        if transposed:
          case referenceCorner
          of 0, 1: # bottom left or top left
            bitmap.combine(symbolBitmap, tt, s, combinationOperator)
          of 2: # bottom right
            bitmap.combine(symbolBitmap, tt - bitmapWidth, s, combinationOperator)
          of 3: # top right
            bitmap.combine(symbolBitmap, tt - bitmapWidth, s, combinationOperator)
          else: discard
          s += bitmapHeight
        else:
          case referenceCorner
          of 0, 2: # bottom left or bottom right
            bitmap.combine(symbolBitmap, s, tt - bitmapHeight, combinationOperator)
          of 1: # top left
            bitmap.combine(symbolBitmap, s, tt, combinationOperator)
          of 3: # top right
            bitmap.combine(symbolBitmap, s, tt, combinationOperator)
          else: discard
          s += bitmapWidth

      inc(currentInstance)

      # Check if there are more symbols in this strip
      var ds: int
      if sbHuff:
        let decodeResult = segment.huffmanDecoder.decodeInt(huffmanDSTable)
        if not decodeResult.success:
          break
        ds = decodeResult.value.int
      else:
        let decodeResult = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iadsStats)
        if not decodeResult.success:
          break
        ds = decodeResult.value

      s += sOffset.int + ds

  # Combine with page bitmap if inline, otherwise append as separate bitmap
  if segment.immediate and segment.streamDecoder != nil:
    let pageSegment = segment.streamDecoder.findPageSegment(segment.segmentHeader.pageAssociation)
    if pageSegment != nil:
      # Cast to PageInformationSegment to access pageBitmap
      let pageInfoSeg = cast[PageInformationSegment](pageSegment)
      if pageInfoSeg != nil:
        let pageBitmap = pageInfoSeg.pageBitmap
        if pageBitmap != nil:
          let externalCombinationOperator = (segment.regionFlags shr 3) and 0x07
          pageBitmap.combine(bitmap, segment.regionBitmapXLocation, segment.regionBitmapYLocation, externalCombinationOperator)
  elif segment.streamDecoder != nil:
    bitmap.bitmapNumber = segment.segmentHeader.segmentNumber
    segment.streamDecoder.appendBitmap(bitmap)

  # Consume any remaining bits
  if segment.streamDecoder != nil:
    segment.streamDecoder.consumeRemainingBits()
