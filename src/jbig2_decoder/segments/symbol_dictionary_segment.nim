## Symbol Dictionary Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../segment_header
import ../stream_decoder_types

type
  SymbolDictionarySegment* = ref object of Segment
    ## Symbol dictionary segment
    noOfExportedSymbols*: int
    noOfNewSymbols*: int
    bitmaps*: seq[JBIG2Bitmap]
    symbolDictionaryFlags*: int
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef
    # Adaptive template values
    symbolDictionaryAdaptiveTemplateX*: array[4, int]
    symbolDictionaryAdaptiveTemplateY*: array[4, int]
    symbolDictionaryRAdaptiveTemplateX*: array[2, int]
    symbolDictionaryRAdaptiveTemplateY*: array[2, int]
    # Stats for context retention
    genericRegionStats*: ArithmeticDecoderStats
    refinementRegionStats*: ArithmeticDecoderStats

proc newSymbolDictionarySegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): SymbolDictionarySegment =
  ## Create a new symbol dictionary segment
  result = SymbolDictionarySegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    noOfExportedSymbols: 0,
    noOfNewSymbols: 0,
    bitmaps: newSeq[JBIG2Bitmap](),
    symbolDictionaryFlags: 0,
    reader: reader,
    streamDecoder: streamDecoder
  )

proc readSymbolDictionaryFlags(segment: SymbolDictionarySegment) =
  ## Read symbol dictionary flags and adaptive template values
  if segment.reader == nil:
    return

  # Read symbol dictionary flags (2 bytes)
  var buff = newSeq[byte](2)
  for i in 0..<2:
    buff[i] = segment.reader.readByte()
  segment.symbolDictionaryFlags = getInt16(buff).int

  # Extract flag values
  let sdHuff = (segment.symbolDictionaryFlags and 1)
  let sdRefAgg = ((segment.symbolDictionaryFlags shr 1) and 1)
  let sdTemplate = ((segment.symbolDictionaryFlags shr 10) and 3)
  let sdRefTemplate = ((segment.symbolDictionaryFlags shr 12) and 1)

  # Read adaptive template values for arithmetic coding
  if sdHuff == 0:
    if sdTemplate == 0:
      # Template 0: read 4 pairs
      for i in 0..<4:
        segment.symbolDictionaryAdaptiveTemplateX[i] = cast[int8](segment.reader.readByte()).int
        segment.symbolDictionaryAdaptiveTemplateY[i] = cast[int8](segment.reader.readByte()).int
    else:
      # Template 1, 2, or 3: read 1 pair
      segment.symbolDictionaryAdaptiveTemplateX[0] = cast[int8](segment.reader.readByte()).int
      segment.symbolDictionaryAdaptiveTemplateY[0] = cast[int8](segment.reader.readByte()).int

  # Read refinement adaptive template values
  if sdRefAgg != 0 and sdRefTemplate == 0:
    segment.symbolDictionaryRAdaptiveTemplateX[0] = cast[int8](segment.reader.readByte()).int
    segment.symbolDictionaryRAdaptiveTemplateY[0] = cast[int8](segment.reader.readByte()).int
    segment.symbolDictionaryRAdaptiveTemplateX[1] = cast[int8](segment.reader.readByte()).int
    segment.symbolDictionaryRAdaptiveTemplateY[1] = cast[int8](segment.reader.readByte()).int

  # Read number of exported symbols (4 bytes)
  buff = newSeq[byte](4)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.noOfExportedSymbols = getInt32(buff).int

  # Read number of new symbols (4 bytes)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.noOfNewSymbols = getInt32(buff).int

method readSegment*(segment: SymbolDictionarySegment) =
  ## Read symbol dictionary segment data
  if segment.reader == nil:
    return

  # Read flags and header information
  readSymbolDictionaryFlags(segment)

  # Extract flag values
  let sdHuff = (segment.symbolDictionaryFlags and 1) != 0
  let sdRefAgg = ((segment.symbolDictionaryFlags shr 1) and 1) != 0
  let sdHuffDH = ((segment.symbolDictionaryFlags shr 2) and 3)  # Huffman table for height differences
  let sdHuffDW = ((segment.symbolDictionaryFlags shr 4) and 3)  # Huffman table for width differences
  let sdHuffBMSize = ((segment.symbolDictionaryFlags shr 6) and 1)  # Huffman table for bitmap size
  let sdHuffAggInst = ((segment.symbolDictionaryFlags shr 7) and 1)  # Huffman table for aggregation instances
  let contextUsed = ((segment.symbolDictionaryFlags shr 8) and 1) != 0
  let sdTemplate = ((segment.symbolDictionaryFlags shr 10) and 3)
  let sdRefTemplate = ((segment.symbolDictionaryFlags shr 12) and 1)

  # Collect input symbols from referred segments
  var numberOfInputSymbols = 0
  var inputSymbolDictionary: SymbolDictionarySegment = nil

  if segment.segmentHeader != nil:
    let referredToSegments = segment.segmentHeader.referredToSegments
    for segNum in referredToSegments:
      # Find the referred segment - this would need to be implemented
      # For now, we'll skip this as it requires access to the decoder's segment list
      discard

  # Calculate symbol code length
  var symbolCodeLength = 0
  var i = 1
  while i < numberOfInputSymbols + segment.noOfNewSymbols:
    symbolCodeLength += 1
    i = i shl 1

  # Initialize bitmaps array
  var bitmaps = newSeq[JBIG2Bitmap](numberOfInputSymbols + segment.noOfNewSymbols)

  # Set up Huffman tables if using Huffman encoding
  var huffmanDHTable: seq[seq[int64]] = @[]
  var huffmanDWTable: seq[seq[int64]] = @[]
  var huffmanBMSizeTable: seq[seq[int64]] = @[]
  var huffmanAggInstTable: seq[seq[int64]] = @[]

  if sdHuff:
    # Select Huffman table for height differences (sdHuffDH)
    if sdHuffDH == 0:
      huffmanDHTable = huffmanTableD
    elif sdHuffDH == 1:
      huffmanDHTable = huffmanTableE
    else:
      # Custom table from code table segment - not implemented yet
      huffmanDHTable = huffmanTableD  # Fallback

    # Select Huffman table for width differences (sdHuffDW)
    if sdHuffDW == 0:
      huffmanDWTable = huffmanTableB
    elif sdHuffDW == 1:
      huffmanDWTable = huffmanTableC
    else:
      # Custom table from code table segment - not implemented yet
      huffmanDWTable = huffmanTableB  # Fallback

    # Select Huffman table for bitmap size (sdHuffBMSize)
    if sdHuffBMSize == 0:
      huffmanBMSizeTable = huffmanTableA
    else:
      # Custom table from code table segment - not implemented yet
      huffmanBMSizeTable = huffmanTableA  # Fallback

    # Select Huffman table for aggregation instances (sdHuffAggInst)
    if sdHuffAggInst == 0:
      huffmanAggInstTable = huffmanTableA
    else:
      # Custom table from code table segment - not implemented yet
      huffmanAggInstTable = huffmanTableA  # Fallback

  # Initialize arithmetic decoder if not using Huffman
  if not sdHuff:
    if contextUsed and inputSymbolDictionary != nil and inputSymbolDictionary.genericRegionStats != nil:
      segment.arithmeticDecoder.resetGenericStats(sdTemplate, inputSymbolDictionary.genericRegionStats)
    else:
      segment.arithmeticDecoder.resetGenericStats(sdTemplate, nil)
    segment.arithmeticDecoder.resetIntStats(symbolCodeLength)
    segment.arithmeticDecoder.start()

  # Initialize refinement stats if needed
  if sdRefAgg:
    if contextUsed and inputSymbolDictionary != nil and inputSymbolDictionary.refinementRegionStats != nil:
      segment.arithmeticDecoder.resetRefinementStats(sdRefTemplate, inputSymbolDictionary.refinementRegionStats)
    else:
      segment.arithmeticDecoder.resetRefinementStats(sdRefTemplate, nil)

  # Decode symbols
  var deltaWidths = newSeq[int64](segment.noOfNewSymbols)
  var deltaHeight: int64 = 0
  var newSymbolIndex = 0

  while newSymbolIndex < segment.noOfNewSymbols:
    var instanceDeltaHeight: int64 = 0

    if sdHuff:
      # Decode using Huffman
      let decodeResult = segment.huffmanDecoder.decodeInt(huffmanDHTable)
      if decodeResult.success:
        instanceDeltaHeight = decodeResult.value
    else:
      # Decode using arithmetic
      instanceDeltaHeight = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iadhStats).value.int64

    deltaHeight += instanceDeltaHeight
    var symbolWidth: int64 = 0
    var totalWidth: int64 = 0
    let startIndex = newSymbolIndex

    # Decode widths and create bitmaps
    while true:
      var deltaWidth: int64 = 0
      var decodeResult: arithmetic_decoder.DecodeIntResult

      if sdHuff:
        let huffResult = segment.huffmanDecoder.decodeInt(huffmanDWTable)
        decodeResult = arithmetic_decoder.DecodeIntResult(value: huffResult.value, success: huffResult.success)
      else:
        decodeResult = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iadwStats)

      if not decodeResult.success:
        break

      deltaWidth = decodeResult.value.int64
      symbolWidth += deltaWidth

      if sdHuff and not sdRefAgg:
        deltaWidths[newSymbolIndex] = symbolWidth
        totalWidth += symbolWidth
      elif sdRefAgg:
        # Refinement/aggregation case
        var refAggNum: int64 = 0

        if sdHuff:
          let huffResult = segment.huffmanDecoder.decodeInt(huffmanAggInstTable)
          if huffResult.success:
            refAggNum = huffResult.value
        else:
          refAggNum = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iaaiStats).value.int64

        if refAggNum == 1:
          # Single symbol refinement
          var symbolID: int64 = 0
          var referenceDX: int64 = 0
          var referenceDY: int64 = 0

          if sdHuff:
            # Read symbol ID directly as bits
            symbolID = segment.reader.readBits(symbolCodeLength).int64
            # Decode reference offsets using huffmanTableO
            let dxResult = segment.huffmanDecoder.decodeInt(huffmanTableO)
            if dxResult.success:
              referenceDX = dxResult.value
            let dyResult = segment.huffmanDecoder.decodeInt(huffmanTableO)
            if dyResult.success:
              referenceDY = dyResult.value
            # Consume remaining bits and start arithmetic decoder for refinement
            segment.reader.consumeRemainingBits()
            segment.arithmeticDecoder.start()
          else:
            symbolID = segment.arithmeticDecoder.decodeIAID(symbolCodeLength, segment.arithmeticDecoder.iaidStats)
            referenceDX = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardxStats).value.int64
            referenceDY = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iardyStats).value.int64

          # Get referred bitmap and create refined bitmap
          if symbolID.int < bitmaps.len and bitmaps[symbolID.int] != nil:
            let referredBitmap = bitmaps[symbolID.int]
            let bitmap = newJBIG2Bitmap(symbolWidth.int, deltaHeight.int, 0)
            bitmap.readGenericRefinementRegion(segment.reader, segment.arithmeticDecoder, sdRefTemplate, false,
                                               referredBitmap, referenceDX.int, referenceDY.int,
                                               segment.symbolDictionaryRAdaptiveTemplateX, segment.symbolDictionaryRAdaptiveTemplateY)
            bitmaps[numberOfInputSymbols + newSymbolIndex] = bitmap
        else:
          # Aggregation - multiple symbols
          let bitmap = newJBIG2Bitmap(symbolWidth.int, deltaHeight.int, 0)
          # Would call readTextRegion here
          bitmaps[numberOfInputSymbols + newSymbolIndex] = bitmap
      else:
        # Direct bitmap decoding
        let bitmap = newJBIG2Bitmap(symbolWidth.int, deltaHeight.int, 0)
        bitmap.readBitmapArithmetic(segment.reader, segment.arithmeticDecoder, sdTemplate, false,
                                    segment.symbolDictionaryAdaptiveTemplateX, segment.symbolDictionaryAdaptiveTemplateY)
        bitmaps[numberOfInputSymbols + newSymbolIndex] = bitmap

      newSymbolIndex += 1

    # Handle collective bitmap for Huffman non-refinement case
    if sdHuff and not sdRefAgg and newSymbolIndex > startIndex:
      var bmSize: int64 = 0

      if sdHuff:
        let bmResult = segment.huffmanDecoder.decodeInt(huffmanBMSizeTable)
        if bmResult.success:
          bmSize = bmResult.value

      if bmSize == 0:
        # Uncompressed bitmap
        let padding = totalWidth mod 8
        let bytesPerRow = ((totalWidth + 7) shr 3).int
        let size = deltaHeight.int * bytesPerRow

        # Read raw bitmap data
        var bitmapData = newSeq[byte](size)
        for idx in 0..<size:
          bitmapData[idx] = segment.reader.readByte()

        # Create collective bitmap
        let collectiveBitmap = newJBIG2Bitmap(totalWidth.int, deltaHeight.int, 0)

        # Parse bitmap data and set pixels
        var dataIdx = 0
        for row in 0..<deltaHeight.int:
          for col in 0..<bytesPerRow:
            let currentByte = bitmapData[dataIdx]
            dataIdx += 1

            let bitsToRead = if col == bytesPerRow - 1: 8 - padding.int else: 8
            for bitPointer in countdown(7, 8 - bitsToRead):
              let mask = 1 shl bitPointer
              let bit = (currentByte.int and mask) shr bitPointer
              let pixelCol = col * 8 + (7 - bitPointer)
              if pixelCol < totalWidth.int:
                collectiveBitmap.setPixel(pixelCol, row, bit)

        # Slice collective bitmap into individual symbols
        var x: int64 = 0
        var j = startIndex
        while j < newSymbolIndex:
          bitmaps[numberOfInputSymbols + j] = collectiveBitmap.getSlice(x.int, 0, deltaWidths[j].int, deltaHeight.int)
          x += deltaWidths[j]
          j += 1
      else:
        # Compressed collective bitmap
        let collectiveBitmap = newJBIG2Bitmap(totalWidth.int, deltaHeight.int, 0)
        # Would read compressed bitmap here

        # Slice collective bitmap into individual symbols
        var x: int64 = 0
        var j = startIndex
        while j < newSymbolIndex:
          bitmaps[numberOfInputSymbols + j] = collectiveBitmap.getSlice(x.int, 0, deltaWidths[j].int, deltaHeight.int)
          x += deltaWidths[j]
          j += 1

  # Export symbols based on export flags
  segment.bitmaps = newSeq[JBIG2Bitmap](segment.noOfExportedSymbols)
  var exportIdx = 0
  var symbolIdx = 0
  var exportFlag = false

  while symbolIdx < numberOfInputSymbols + segment.noOfNewSymbols:
    var run: int64 = 0
    if sdHuff:
      let runResult = segment.huffmanDecoder.decodeInt(huffmanTableA)
      if runResult.success:
        run = runResult.value
    else:
      run = segment.arithmeticDecoder.decodeInt(segment.arithmeticDecoder.iaexStats).value.int64

    if exportFlag:
      for cnt in 0..<run:
        if exportIdx < segment.bitmaps.len and symbolIdx < bitmaps.len:
          segment.bitmaps[exportIdx] = bitmaps[symbolIdx]
          exportIdx += 1
          symbolIdx += 1
    else:
      symbolIdx += run.int

    exportFlag = not exportFlag

  # Handle context retention
  let contextRetained = ((segment.symbolDictionaryFlags shr 9) and 1)
  if not sdHuff and contextRetained == 1:
    # Would copy stats here
    discard

  # Consume any remaining bits
  if segment.streamDecoder != nil:
    # Would call consumeRemainingBits on decoder
    discard
