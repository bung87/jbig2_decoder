## JBIG2Bitmap tests
import std/[os, strformat]
import jbig2_decoder/jbig2_bitmap


# Test basic bitmap creation
block BasicBitmapCreation:
  let bitmap = newJBIG2Bitmap(10, 10, 0)
  
  doAssert bitmap.width == 10, "Bitmap width should be 10"
  doAssert bitmap.height == 10, "Bitmap height should be 10"
  doAssert bitmap.bitmapNumber == 0, "Bitmap number should be 0"

# Test pixel operations
block PixelOperations:
  let bitmap = newJBIG2Bitmap(50, 50, 0)
  
  # Test setting and getting pixels
  bitmap.setPixel(10, 10, 1)
  doAssert bitmap.getPixel(10, 10) == 1, "Pixel at (10,10) should be set to 1"
  
  bitmap.setPixel(10, 10, 0)
  doAssert bitmap.getPixel(10, 10) == 0, "Pixel at (10,10) should be set to 0"
  
  # Test bounds checking
  doAssert bitmap.getPixel(-1, -1) == 0, "Out of bounds should return 0"
  doAssert bitmap.getPixel(100, 100) == 0, "Out of bounds should return 0"
  
  # Test that setting out of bounds doesn't crash
  bitmap.setPixel(-1, -1, 1)
  bitmap.setPixel(100, 100, 1)

# Test bitmap data conversion
block BitmapDataConversion:
  let bitmap = newJBIG2Bitmap(8, 8, 0)
  
  # Create a simple pattern
  for x in 0..<8:
    for y in 0..<8:
      bitmap.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  let data = bitmap.getData()
  doAssert data.len == 64, "8x8 bitmap should produce 64 bytes of data (1 byte per pixel)"

# Test bitmap combination
block BitmapCombination:
  let source = newJBIG2Bitmap(5, 5, 0)
  let destination = newJBIG2Bitmap(10, 10, 0)
  
  # Fill source with a pattern
  for x in 0..<5:
    for y in 0..<5:
      source.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  # Combine source into destination at position (2, 2) using OR operator
  destination.combine(source, 2, 2, 0)
  
  # Verify the combination
  for x in 0..<5:
    for y in 0..<5:
      doAssert destination.getPixel(2 + x, 2 + y) == source.getPixel(x, y), "Combined bitmap should match source pattern"

# Test bitmap clearing
block BitmapClearing:
  let bitmap = newJBIG2Bitmap(10, 10, 0)
  
  # Fill with 1 values
  for x in 0..<10:
    for y in 0..<10:
      bitmap.setPixel(x, y, 1)
  
  # Clear the bitmap to 0
  bitmap.clear(0)
  
  # Verify all pixels are 0
  for x in 0..<10:
    for y in 0..<10:
      doAssert bitmap.getPixel(x, y) == 0, "All pixels should be 0 after clearing"

# Test bitmap pointer operations
block BitmapPointerOperations:
  let bitmap = newJBIG2Bitmap(20, 20, 0)
  let pointer = newBitmapPointer(bitmap, 5, 5)
  
  # Test setting pixel via pointer
  pointer.setPixel(true)
  doAssert bitmap.getPixel(5, 5) == 1, "Pixel at pointer position should be set"
  
  # Test getting pixel via pointer
  doAssert pointer.getPixel() == true, "Pointer should return true for set pixel"
