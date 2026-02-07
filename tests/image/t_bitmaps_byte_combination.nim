## JBIG2Bitmap byte combination tests
import std/[os, strformat]
import jbig2_decoder/jbig2_bitmap



# Test basic getData
block BasicGetData:
  let bitmap = newJBIG2Bitmap(16, 2, 0)
  
  # Set specific pattern: first row all pixels, second row alternating
  for x in 0..<16:
    bitmap.setPixel(x, 0, 1)  # All pixels in first row
    bitmap.setPixel(x, 1, if x mod 2 == 0: 1 else: 0)  # Alternating in second row
  
  let bitmapData = bitmap.getData()
  
  # getData returns one byte per pixel (0 or 255)
  doAssert bitmapData.len == 32, "16x2 bitmap should produce 32 bytes of data (1 byte per pixel)"
  
  # First row should be all 255s (white)
  for x in 0..<16:
    doAssert bitmapData[x] == 255, "First row pixels should be 255 (white)"
  
  # Second row should be alternating (255, 0, 255, 0, ...)
  for x in 0..<16:
    let expected = if x mod 2 == 0: 255'u8 else: 0'u8
    doAssert bitmapData[16 + x] == expected, "Second row should be alternating"

# Test getData with switchPixelColor
block GetDataWithColorSwitch:
  let bitmap = newJBIG2Bitmap(8, 1, 0)
  
  # Set alternating pattern
  for x in 0..<8:
    bitmap.setPixel(x, 0, if x mod 2 == 0: 1 else: 0)
  
  let normalData = bitmap.getData(switchPixelColor = false)
  let invertedData = bitmap.getData(switchPixelColor = true)
  
  doAssert normalData.len == 8, "8x1 bitmap should produce 8 bytes"
  doAssert invertedData.len == 8, "8x1 bitmap should produce 8 bytes"
  
  # Normal: 1 -> 255, 0 -> 0
  # Inverted: 1 -> 0, 0 -> 255
  for x in 0..<8:
    let normalExpected = if x mod 2 == 0: 255'u8 else: 0'u8
    let invertedExpected = if x mod 2 == 0: 0'u8 else: 255'u8
    doAssert normalData[x] == normalExpected, "Normal data should match"
    doAssert invertedData[x] == invertedExpected, "Inverted data should match"

# Test getData with different bitmap sizes
block GetDataDifferentSizes:
  # Test 1x1 bitmap
  let bitmap1 = newJBIG2Bitmap(1, 1, 0)
  bitmap1.setPixel(0, 0, 1)
  let data1 = bitmap1.getData()
  doAssert data1.len == 1, "1x1 bitmap should produce 1 byte"
  doAssert data1[0] == 255'u8, "Set pixel should be 255"
  
  # Test 4x4 bitmap
  let bitmap2 = newJBIG2Bitmap(4, 4, 0)
  for x in 0..<4:
    for y in 0..<4:
      bitmap2.setPixel(x, y, 1)
  let data2 = bitmap2.getData()
  doAssert data2.len == 16, "4x4 bitmap should produce 16 bytes"
  for i in 0..<16:
    doAssert data2[i] == 255'u8, "All pixels should be 255"

# Test getData with empty bitmap
block GetDataEmptyBitmap:
  let bitmap = newJBIG2Bitmap(10, 10, 0)
  
  # All pixels are 0 by default
  let data = bitmap.getData()
  doAssert data.len == 100, "10x10 bitmap should produce 100 bytes"
  for i in 0..<100:
    doAssert data[i] == 0'u8, "All pixels should be 0 (black)"
