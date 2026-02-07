## Page Information Segment
import ../segment
import ../jbig2_bitmap
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops

type
  PageInformationSegment* = ref object of Segment
    ## Page information segment
    pageBitmap*: JBIG2Bitmap
    pageBitmapWidth*: int
    pageBitmapHeight*: int
    xResolution*: int
    yResolution*: int
    pageInformationFlags*: int
    pageStriping*: int
    reader*: Big2StreamReader

proc newPageInformationSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, reader: Big2StreamReader = nil): PageInformationSegment =
  ## Create a new page information segment
  result = PageInformationSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    pageBitmap: nil,
    pageBitmapWidth: 0,
    pageBitmapHeight: 0,
    xResolution: 0,
    yResolution: 0,
    pageInformationFlags: 0,
    pageStriping: 0,
    reader: reader
  )

method readSegment*(segment: PageInformationSegment) =
  ## Read page information segment data
  if segment.reader != nil:
    var buff = newSeq[byte](4)

    # Read page bitmap width
    for i in 0..<4:
      buff[i] = segment.reader.readByte()
    segment.pageBitmapWidth = getInt32(buff).int

    # Read page bitmap height
    for i in 0..<4:
      buff[i] = segment.reader.readByte()
    segment.pageBitmapHeight = getInt32(buff).int

    # Read X resolution
    for i in 0..<4:
      buff[i] = segment.reader.readByte()
    segment.xResolution = getInt32(buff).int

    # Read Y resolution
    for i in 0..<4:
      buff[i] = segment.reader.readByte()
    segment.yResolution = getInt32(buff).int

    # Read page information flags
    segment.pageInformationFlags = segment.reader.readByte().int

    # Read page striping (2 bytes)
    buff = newSeq[byte](2)
    for i in 0..<2:
      buff[i] = segment.reader.readByte()
    segment.pageStriping = getInt16(buff).int

    # Get default pixel value from flags
    let defaultPixel = (segment.pageInformationFlags shr 2) and 0x01

    # Determine actual height
    var height: int
    if segment.pageBitmapHeight == -1:
      height = segment.pageStriping and 0x7FFF
    else:
      height = segment.pageBitmapHeight

    # Create page bitmap
    segment.pageBitmap = newJBIG2Bitmap(segment.pageBitmapWidth, height, 0)

    # Clear bitmap with default pixel value
    segment.pageBitmap.clear(defaultPixel)

proc getPageBitmap*(segment: PageInformationSegment): JBIG2Bitmap =
  ## Get the page bitmap
  result = segment.pageBitmap

proc getPageBitmapWidth*(segment: PageInformationSegment): int =
  ## Get the page bitmap width
  result = segment.pageBitmapWidth

proc getPageBitmapHeight*(segment: PageInformationSegment): int =
  ## Get the page bitmap height
  result = segment.pageBitmapHeight

proc getPageInformationFlags*(segment: PageInformationSegment): int =
  ## Get the page information flags
  result = segment.pageInformationFlags
