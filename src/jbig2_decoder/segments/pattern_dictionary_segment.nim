## Pattern Dictionary Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops
import ../stream_decoder_types

type
  PatternDictionarySegment* = ref object of Segment
    ## Pattern dictionary segment for halftone regions
    patternDictionaryFlags*: int
    width*: int
    height*: int
    grayMax*: int
    size*: int
    bitmaps*: seq[JBIG2Bitmap]
    reader*: Big2StreamReader
    streamDecoder*: JBIG2StreamDecoderRef

proc newPatternDictionarySegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): PatternDictionarySegment =
  ## Create a new pattern dictionary segment
  result = PatternDictionarySegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    patternDictionaryFlags: 0,
    width: 0,
    height: 0,
    grayMax: 0,
    size: 0,
    bitmaps: @[],
    reader: reader,
    streamDecoder: streamDecoder
  )

method readSegment*(segment: PatternDictionarySegment) =
  ## Read pattern dictionary segment data
  ## Patterns are used by halftone regions to represent grayscale images
  if segment.reader == nil:
    return

  # Read pattern dictionary flags (1 byte)
  segment.patternDictionaryFlags = segment.reader.readByte().int

  # Read width and height (2 bytes total)
  segment.width = segment.reader.readByte().int
  segment.height = segment.reader.readByte().int

  # Debug: echo "pattern dictionary size = ", segment.width, " , ", segment.height

  # Read gray max (4 bytes) - determines number of patterns
  var buff = newSeq[byte](4)
  for i in 0..<4:
    buff[i] = segment.reader.readByte()
  segment.grayMax = getInt32(buff).int

  # Debug: echo "grey max = ", segment.grayMax

  # Extract flags
  let useMMR = (segment.patternDictionaryFlags and 0x01) != 0
  let templateId = (segment.patternDictionaryFlags shr 1) and 0x03

  # Set up adaptive template for pattern dictionary
  var genericBAdaptiveTemplateX = @[segment.width.int, -3, 2, -2]
  var genericBAdaptiveTemplateY = @[0.int, -1, -2, -2]

  # Reset arithmetic decoder stats if not using MMR
  if not useMMR:
    segment.arithmeticDecoder.resetGenericStats(templateId, nil)
    segment.arithmeticDecoder.start()

  # Calculate number of patterns
  segment.size = segment.grayMax + 1

  # Create collective bitmap containing all patterns
  let collectiveBitmap = newJBIG2Bitmap(segment.size * segment.width, segment.height, 0)
  collectiveBitmap.clear(0)

  # Read the collective bitmap
  let dataLength = if segment.segmentHeader != nil: segment.segmentHeader.dataLength else: 0
  let mmrDataLength = if useMMR: dataLength - 7 else: 0
  if useMMR:
    collectiveBitmap.readBitmapMMR(segment.reader, segment.mmrDecoder, mmrDataLength)
  else:
    collectiveBitmap.readBitmapArithmetic(segment.reader, segment.arithmeticDecoder, templateId, false,
                                          genericBAdaptiveTemplateX, genericBAdaptiveTemplateY)

  # Slice collective bitmap into individual patterns
  segment.bitmaps = newSeq[JBIG2Bitmap](segment.size)
  var x = 0
  for i in 0..<segment.size:
    segment.bitmaps[i] = collectiveBitmap.getSlice(x, 0, segment.width, segment.height)
    x += segment.width

proc getBitmaps*(segment: PatternDictionarySegment): seq[JBIG2Bitmap] =
  ## Get the pattern bitmaps
  return segment.bitmaps

proc getSize*(segment: PatternDictionarySegment): int =
  ## Get the number of patterns
  return segment.size
