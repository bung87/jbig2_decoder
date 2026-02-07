## JBIG2 Bitmap implementation
import ./arithmetic_decoder
import ./mmr_decoder
import ./stream_reader

type
  JBIG2Bitmap* = ref object
    ## JBIG2 bitmap representation
    width*: int
    height*: int
    data*: seq[seq[byte]]  # 2D array of pixel data
    bitmapNumber*: int

proc newJBIG2Bitmap*(width, height, bitmapNumber: int): JBIG2Bitmap =
  ## Create a new JBIG2 bitmap with specified dimensions
  result = JBIG2Bitmap(
    width: width,
    height: height,
    bitmapNumber: bitmapNumber
  )
  # Initialize data as 2D array
  result.data = newSeq[seq[byte]](height)
  for i in 0..<height:
    result.data[i] = newSeq[byte](width)

proc setPixel*(bitmap: JBIG2Bitmap, x, y: int, value: int) =
  ## Set a pixel value at the specified coordinates
  if x >= 0 and x < bitmap.width and y >= 0 and y < bitmap.height:
    bitmap.data[y][x] = value.byte

proc getPixel*(bitmap: JBIG2Bitmap, x, y: int): int =
  ## Get a pixel value at the specified coordinates
  if x >= 0 and x < bitmap.width and y >= 0 and y < bitmap.height:
    result = bitmap.data[y][x].int
  else:
    result = 0

proc clear*(bitmap: JBIG2Bitmap, value: int) =
  ## Clear the bitmap to a specific value
  for y in 0..<bitmap.height:
    for x in 0..<bitmap.width:
      bitmap.data[y][x] = value.byte

proc setBitmapNumber*(bitmap: JBIG2Bitmap, number: int) =
  ## Set the bitmap number
  bitmap.bitmapNumber = number

proc getBitmapNumber*(bitmap: JBIG2Bitmap): int =
  ## Get the bitmap number
  result = bitmap.bitmapNumber

proc combine*(bitmap: JBIG2Bitmap, source: JBIG2Bitmap, x, y: int, operator: int) =
  ## Combine another bitmap into this one at the specified position
  ## operator: 0=OR, 1=AND, 2=XOR, 3=XNOR, 4=REPLACE
  for sy in 0..<source.height:
    for sx in 0..<source.width:
      let dx = x + sx
      let dy = y + sy
      if dx >= 0 and dx < bitmap.width and dy >= 0 and dy < bitmap.height:
        let sourcePixel = source.getPixel(sx, sy)
        let destPixel = bitmap.getPixel(dx, dy)
        var resultPixel: int
        case operator
        of 0: resultPixel = destPixel or sourcePixel  # OR
        of 1: resultPixel = destPixel and sourcePixel  # AND
        of 2: resultPixel = destPixel xor sourcePixel  # XOR
        of 3: resultPixel = not (destPixel xor sourcePixel).bool.ord  # XNOR
        of 4: resultPixel = sourcePixel  # REPLACE
        else: resultPixel = destPixel or sourcePixel  # Default to OR
        bitmap.setPixel(dx, dy, resultPixel)

proc expand*(bitmap: JBIG2Bitmap, newHeight: int, defaultPixel: int) =
  ## Expand the bitmap to a new height
  if newHeight > bitmap.height:
    let oldHeight = bitmap.height
    bitmap.data.setLen(newHeight)
    for i in oldHeight..<newHeight:
      bitmap.data[i] = newSeq[byte](bitmap.width)
      for j in 0..<bitmap.width:
        bitmap.data[i][j] = defaultPixel.byte
    bitmap.height = newHeight

proc getSlice*(bitmap: JBIG2Bitmap, x, y, width, height: int): JBIG2Bitmap =
  ## Get a slice/portion of the bitmap
  result = newJBIG2Bitmap(width, height, 0)
  for row in y..<y+height:
    for col in x..<x+width:
      let pixel = bitmap.getPixel(col, row)
      result.setPixel(col - x, row - y, pixel)

proc getData*(bitmap: JBIG2Bitmap, switchPixelColor: bool = false): seq[byte] =
  ## Get the bitmap data as a flat byte sequence
  ## If switchPixelColor is true, invert the pixel values (0 becomes 255, 1 becomes 0)
  result = newSeq[byte](bitmap.width * bitmap.height)
  var idx = 0
  for y in 0..<bitmap.height:
    for x in 0..<bitmap.width:
      var pixel = bitmap.getPixel(x, y)
      if switchPixelColor:
        # Invert pixel: 0 -> 255 (white), 1 -> 0 (black)
        pixel = if pixel == 0: 255 else: 0
      else:
        # Normal: 0 -> 0 (black), 1 -> 255 (white)
        pixel = if pixel == 0: 0 else: 255
      result[idx] = pixel.byte
      idx += 1

# Bitmap pointer for efficient access
type
  BitmapPointer* = object
    bitmap*: JBIG2Bitmap
    x*, y*: int

proc newBitmapPointer*(bitmap: JBIG2Bitmap, x, y: int): BitmapPointer =
  result.bitmap = bitmap
  result.x = x
  result.y = y

proc getPixel*(pointer: BitmapPointer): bool =
  result = pointer.bitmap.getPixel(pointer.x, pointer.y) != 0

proc setPixel*(pointer: BitmapPointer, value: bool) =
  pointer.bitmap.setPixel(pointer.x, pointer.y, if value: 1 else: 0)

proc duplicateRow*(bitmap: JBIG2Bitmap, targetRow, sourceRow: int) =
  ## Duplicate a row from source to target
  if sourceRow >= 0 and sourceRow < bitmap.height and targetRow >= 0 and targetRow < bitmap.height:
    for x in 0..<bitmap.width:
      bitmap.data[targetRow][x] = bitmap.data[sourceRow][x]

proc readBitmapMMR*(bitmap: JBIG2Bitmap, reader: Big2StreamReader, mmrDecoder: MMRDecoder, dataLength: int) =
  ## Read bitmap using MMR (Modified Modified READ) decoding
  ## This is a simplified implementation based on the C# reference

  # Initialize reference line with imaginary white pixels
  var referenceLine = newSeq[int](bitmap.width + 2)
  referenceLine[bitmap.width] = bitmap.width
  referenceLine[bitmap.width + 1] = bitmap.width

  var codingLine = newSeq[int](bitmap.width + 2)

  for row in 0..<bitmap.height:
    # Initialize coding line
    codingLine[0] = 0
    var codingI: int = 0
    var a0: int = -1

    # Initialize reference index
    var referenceI: int = 0
    while referenceLine[referenceI] < 0:
      referenceI += 1

    # Decode line using 2-D MMR
    var done = false
    while not done:
      # Get two code words
      let code1 = mmrDecoder.get2DCode()
      discard mmrDecoder.get2DCode()  # code2 - not used directly

      if code1 == twoDimensionalPass:
        # Pass mode - copy reference run
        if a0 < 0:
          codingI += 1
          codingLine[codingI] = referenceLine[referenceI + 1]
        else:
          codingLine[codingI] = referenceLine[referenceI + 1]
        a0 = codingLine[codingI]
        codingI += 1

        if referenceLine[referenceI + 1] < bitmap.width:
          referenceI += 2
          while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
            referenceI += 2
      elif code1 == twoDimensionalHorizontal:
        # Horizontal mode
        let h1 = mmrDecoder.getWhiteCode()
        let h2 = mmrDecoder.getBlackCode()
        if codingI > 0 and codingLine[codingI] < 0:
          codingLine[codingI] = codingLine[codingI - 1] - h1
        else:
          codingLine[codingI] = codingLine[codingI] + h1
        codingI += 1
        a0 = codingLine[codingI - 1]
        codingLine[codingI] = a0 + h2
        codingI += 1
        a0 = codingLine[codingI - 1]

        while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
          referenceI += 2
      elif code1 == twoDimensionalVertical0:
        codingLine[codingI] = referenceLine[referenceI]
        a0 = codingLine[codingI]
        codingI += 1
        if referenceLine[referenceI] < bitmap.width:
          referenceI += 1
          while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
            referenceI += 2
      elif code1 == twoDimensionalVerticalR1:
        codingLine[codingI] = referenceLine[referenceI] + 1
        a0 = codingLine[codingI]
        codingI += 1
        if referenceLine[referenceI] < bitmap.width:
          referenceI += 1
          while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
            referenceI += 2
      elif code1 == twoDimensionalVerticalR2:
        codingLine[codingI] = referenceLine[referenceI] + 2
        a0 = codingLine[codingI]
        codingI += 1
        if referenceLine[referenceI] < bitmap.width:
          referenceI += 1
          while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
            referenceI += 2
      elif code1 == twoDimensionalVerticalR3:
        codingLine[codingI] = referenceLine[referenceI] + 3
        a0 = codingLine[codingI]
        codingI += 1
        if referenceLine[referenceI] < bitmap.width:
          referenceI += 1
          while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
            referenceI += 2
      elif code1 == twoDimensionalVerticalL1:
        codingLine[codingI] = referenceLine[referenceI] - 1
        a0 = codingLine[codingI]
        codingI += 1
        if referenceI > 0:
          referenceI -= 1
        else:
          referenceI += 1
        while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
          referenceI += 2
      elif code1 == twoDimensionalVerticalL2:
        codingLine[codingI] = referenceLine[referenceI] - 2
        a0 = codingLine[codingI]
        codingI += 1
        if referenceI > 0:
          referenceI -= 1
        else:
          referenceI += 1
        while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
          referenceI += 2
      elif code1 == twoDimensionalVerticalL3:
        codingLine[codingI] = referenceLine[referenceI] - 3
        a0 = codingLine[codingI]
        codingI += 1
        if referenceI > 0:
          referenceI -= 1
        else:
          referenceI += 1
        while referenceLine[referenceI] <= a0 and referenceLine[referenceI] < bitmap.width:
          referenceI += 2
      else:
        # Illegal code
        discard

    codingLine[codingI] = bitmap.width
    codingI += 1

    # Set pixels based on coding line
    var j = 0
    while codingLine[j] < bitmap.width:
      for col in codingLine[j]..<codingLine[j + 1]:
        bitmap.setPixel(col.int, row, 1)
      j += 2

  # Skip to end of data if length is specified
  if dataLength >= 0:
    mmrDecoder.skipTo(dataLength.int64)
  else:
    # Check for EOFB (End of File Block) marker
    if mmrDecoder.get24Bits() != 0x001001:
      # Missing EOFB - this is a warning condition
      discard

proc readBitmapArithmetic*(bitmap: JBIG2Bitmap, reader: Big2StreamReader, arithmeticDecoder: ArithmeticDecoder,
                          gbTemplate: int, typicalPrediction: bool, adaptiveTemplateX, adaptiveTemplateY: openArray[int]) =
  ## Read bitmap using arithmetic coding
  ## Implements arithmetic decoding based on C# reference implementation

  # Initialize typical prediction context
  var ltpCX: int64 = 0
  if typicalPrediction:
    case gbTemplate
    of 0: ltpCX = 0x3953
    of 1: ltpCX = 0x079a
    of 2: ltpCX = 0x0e3
    of 3: ltpCX = 0x18a
    else: discard

  var ltp = false

  for row in 0..<bitmap.height:
    # Handle typical prediction
    if typicalPrediction:
      let bit = arithmeticDecoder.decodeBit(ltpCX, arithmeticDecoder.genericRegionStats)
      if bit != 0:
        ltp = not ltp

      if ltp:
        # Copy previous row
        duplicateRow(bitmap, row, row - 1)
        continue

    var pixel: int
    var cx, cx0, cx1, cx2: int64

    # Decode row based on template
    case gbTemplate
    of 0:
      # Template 0: 10-bit context
      # Initialize context from previous rows
      cx0 = (bitmap.getPixel(0, row - 2) shl 1) or bitmap.getPixel(1, row - 2)

      cx1 = (bitmap.getPixel(0, row - 1) shl 2) or
            (bitmap.getPixel(1, row - 1) shl 1) or
            bitmap.getPixel(2, row - 1)

      cx2 = 0

      for col in 0..<bitmap.width:
        cx = (bit32ShiftL(cx0, 13)) or (bit32ShiftL(cx1, 8)) or (bit32ShiftL(cx2, 4)) or
             (bitmap.getPixel(col + adaptiveTemplateX[0], row + adaptiveTemplateY[0]) shl 3) or
             (bitmap.getPixel(col + adaptiveTemplateX[1], row + adaptiveTemplateY[1]) shl 2) or
             (bitmap.getPixel(col + adaptiveTemplateX[2], row + adaptiveTemplateY[2]) shl 1) or
             bitmap.getPixel(col + adaptiveTemplateX[3], row + adaptiveTemplateY[3])

        pixel = arithmeticDecoder.decodeBit(cx, arithmeticDecoder.genericRegionStats)
        if pixel != 0:
          bitmap.setPixel(col, row, 1)

        # Update contexts
        cx0 = (bit32ShiftL(cx0, 1) or bitmap.getPixel(col + 2, row - 2)) and 0x07
        cx1 = (bit32ShiftL(cx1, 1) or bitmap.getPixel(col + 3, row - 1)) and 0x1F
        cx2 = (bit32ShiftL(cx2, 1) or pixel) and 0x0F

    of 1:
      # Template 1: 9-bit context
      cx0 = (bitmap.getPixel(0, row - 2) shl 2) or
            (bitmap.getPixel(1, row - 2) shl 1) or
            bitmap.getPixel(2, row - 2)

      cx1 = (bitmap.getPixel(0, row - 1) shl 2) or
            (bitmap.getPixel(1, row - 1) shl 1) or
            bitmap.getPixel(2, row - 1)

      cx2 = 0

      for col in 0..<bitmap.width:
        cx = (bit32ShiftL(cx0, 9)) or (bit32ShiftL(cx1, 4)) or (bit32ShiftL(cx2, 1)) or
             bitmap.getPixel(col + adaptiveTemplateX[0], row + adaptiveTemplateY[0])

        pixel = arithmeticDecoder.decodeBit(cx, arithmeticDecoder.genericRegionStats)
        if pixel != 0:
          bitmap.setPixel(col, row, 1)

        cx0 = (bit32ShiftL(cx0, 1) or bitmap.getPixel(col + 3, row - 2)) and 0x0F
        cx1 = (bit32ShiftL(cx1, 1) or bitmap.getPixel(col + 3, row - 1)) and 0x1F
        cx2 = (bit32ShiftL(cx2, 1) or pixel) and 0x07

    of 2:
      # Template 2: 8-bit context
      cx0 = (bitmap.getPixel(0, row - 2) shl 1) or bitmap.getPixel(1, row - 2)

      cx1 = (bitmap.getPixel(0, row - 1) shl 1) or bitmap.getPixel(1, row - 1)

      cx2 = 0

      for col in 0..<bitmap.width:
        cx = (bit32ShiftL(cx0, 7)) or (bit32ShiftL(cx1, 3)) or (bit32ShiftL(cx2, 1)) or
             bitmap.getPixel(col + adaptiveTemplateX[0], row + adaptiveTemplateY[0])

        pixel = arithmeticDecoder.decodeBit(cx, arithmeticDecoder.genericRegionStats)
        if pixel != 0:
          bitmap.setPixel(col, row, 1)

        cx0 = (bit32ShiftL(cx0, 1) or bitmap.getPixel(col + 2, row - 2)) and 0x07
        cx1 = (bit32ShiftL(cx1, 1) or bitmap.getPixel(col + 2, row - 1)) and 0x0F
        cx2 = (bit32ShiftL(cx2, 1) or pixel) and 0x03

    of 3:
      # Template 3: 7-bit context
      cx1 = (bitmap.getPixel(0, row - 1) shl 1) or bitmap.getPixel(1, row - 1)

      cx2 = 0

      for col in 0..<bitmap.width:
        cx = (bit32ShiftL(cx1, 5)) or (bit32ShiftL(cx2, 1)) or
             bitmap.getPixel(col + adaptiveTemplateX[0], row + adaptiveTemplateY[0])

        pixel = arithmeticDecoder.decodeBit(cx, arithmeticDecoder.genericRegionStats)
        if pixel != 0:
          bitmap.setPixel(col, row, 1)

        cx1 = (bit32ShiftL(cx1, 1) or bitmap.getPixel(col + 2, row - 1)) and 0x1F
        cx2 = (bit32ShiftL(cx2, 1) or pixel) and 0x0F

    else:
      discard

proc readGenericRefinementRegion*(bitmap: JBIG2Bitmap, reader: Big2StreamReader, arithmeticDecoder: ArithmeticDecoder,
                                 refTemplate: int, typicalPrediction: bool, referenceBitmap: JBIG2Bitmap,
                                 referenceX, referenceY: int, adaptiveTemplateX, adaptiveTemplateY: openArray[int]) =
  ## Read generic refinement region
  ## Decodes a bitmap as a refinement of a reference bitmap
  ## refTemplate: 0 or 1 (different context configurations)
  ## typicalPrediction: enables typical prediction for efficiency
  ## referenceBitmap: the base bitmap to refine
  ## referenceX, referenceY: offset of the reference bitmap

  var ltpCX: int64
  if refTemplate != 0:
    ltpCX = 0x008
  else:
    ltpCX = 0x0010

  var ltp = false

  for row in 0..<bitmap.height:
    if refTemplate != 0:
      # Template 1: 4-bit context from current bitmap, 4-bit from reference
      var cx0 = bitmap.getPixel(0, row - 1)
      var cx3 = (referenceBitmap.getPixel(-1 - referenceX, row - referenceY) shl 1) or
                referenceBitmap.getPixel(-referenceX, row - referenceY)
      var cx4 = referenceBitmap.getPixel(-referenceX, row + 1 - referenceY)

      var typicalCX0, typicalCX1, typicalCX2: int64 = 0

      if typicalPrediction:
        typicalCX0 = (referenceBitmap.getPixel(-1 - referenceX, row - 1 - referenceY) shl 2) or
                     (referenceBitmap.getPixel(-referenceX, row - 1 - referenceY) shl 1) or
                     referenceBitmap.getPixel(1 - referenceX, row - 1 - referenceY)
        typicalCX1 = (referenceBitmap.getPixel(-1 - referenceX, row - referenceY) shl 2) or
                     (referenceBitmap.getPixel(-referenceX, row - referenceY) shl 1) or
                     referenceBitmap.getPixel(1 - referenceX, row - referenceY)
        typicalCX2 = (referenceBitmap.getPixel(-1 - referenceX, row + 1 - referenceY) shl 2) or
                     (referenceBitmap.getPixel(-referenceX, row + 1 - referenceY) shl 1) or
                     referenceBitmap.getPixel(1 - referenceX, row + 1 - referenceY)

      for col in 0..<bitmap.width:
        # Update sliding contexts
        cx0 = ((cx0 shl 1) or bitmap.getPixel(col + 1, row - 1)) and 0x07
        cx3 = ((cx3 shl 1) or referenceBitmap.getPixel(col + 1 - referenceX, row - referenceY)) and 0x07
        cx4 = ((cx4 shl 1) or referenceBitmap.getPixel(col + 1 - referenceX, row + 1 - referenceY)) and 0x03

        if typicalPrediction:
          typicalCX0 = ((typicalCX0 shl 1) or referenceBitmap.getPixel(col + 2 - referenceX, row - 1 - referenceY)) and 0x07
          typicalCX1 = ((typicalCX1 shl 1) or referenceBitmap.getPixel(col + 2 - referenceX, row - referenceY)) and 0x07
          typicalCX2 = ((typicalCX2 shl 1) or referenceBitmap.getPixel(col + 2 - referenceX, row + 1 - referenceY)) and 0x07

          let decodeBit = arithmeticDecoder.decodeBit(ltpCX, arithmeticDecoder.refinementRegionStats)
          if decodeBit != 0:
            ltp = not ltp
