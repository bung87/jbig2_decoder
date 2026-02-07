## JBIG2Bitmap checksum tests
import std/[os, strformat, strutils]
import jbig2_decoder
import jbig2_decoder/jbig2_bitmap


# Test checksum for simple bitmap
block SimpleBitmapChecksum:
  let bitmap = newJBIG2Bitmap(10, 10, 0)
  
  # Create a simple pattern
  for x in 0..<10:
    for y in 0..<10:
      bitmap.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  let bitmapData = bitmap.getData()
  let checksum = computeChecksum(bitmapData)
  
  doAssert checksum.len > 0, "Pattern bitmap checksum should not be empty"
  doAssert checksum[0].isDigit() == true, "Checksum should start with a digit"

# Test checksum consistency
block ChecksumConsistency:
  let bitmap1 = newJBIG2Bitmap(8, 8, 0)
  let bitmap2 = newJBIG2Bitmap(8, 8, 0)
  
  # Fill both with identical patterns
  for x in 0..<8:
    for y in 0..<8:
      bitmap1.setPixel(x, y, if (x * y) mod 3 == 0: 1 else: 0)
      bitmap2.setPixel(x, y, if (x * y) mod 3 == 0: 1 else: 0)
  
  let checksum1 = computeChecksum(bitmap1.getData())
  let checksum2 = computeChecksum(bitmap2.getData())
  
  doAssert checksum1 == checksum2, "Identical bitmaps should produce identical checksums"

# Test checksum differences
block ChecksumDifferences:
  let bitmap1 = newJBIG2Bitmap(8, 8, 0)
  let bitmap2 = newJBIG2Bitmap(8, 8, 0)
  
  # Fill with different patterns
  for x in 0..<8:
    for y in 0..<8:
      bitmap1.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
      bitmap2.setPixel(x, y, if (x * y) mod 2 == 0: 1 else: 0)
  
  let checksum1 = computeChecksum(bitmap1.getData())
  let checksum2 = computeChecksum(bitmap2.getData())
  
  doAssert checksum1 != checksum2, "Different bitmaps should produce different checksums"
