## Checksum validation tests for JBIG2 files
import std/[strutils, math, strformat]
import jbig2_decoder
import jbig2_decoder/jbig2_bitmap
import ../testdata/jbig2_test_config

# Test Compute checksum for simple bitmap
block ComputeChecksumForSimpleBitmap:
  let bitmap = newJBIG2Bitmap(8, 8, 0)
  
  # Create a simple pattern
  for x in 0..<8:
    for y in 0..<8:
      bitmap.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  let bitmapData = getData(bitmap)
  let checksum = computeChecksum(bitmapData)
  
  doAssert checksum.len > 0, "Checksum should not be empty"
  doAssert checksum[0].isDigit() == true, "Checksum should start with a digit"
  
  when defined(VERBOSE_OUTPUT):
    echo fmt"Simple bitmap checksum: {checksum}"

  # Test Compute checksum for complex bitmap
block ComputeChecksumForComplexBitmap:
  let bitmap = newJBIG2Bitmap(32, 32, 0)
  
  # Create a complex pattern (concentric circles)
  let centerX = 16
  let centerY = 16
  
  for x in 0..<32:
    for y in 0..<32:
      let distance = sqrt(float((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY)))
      let pixelValue = if (distance <= 8) or (distance > 12 and distance <= 16): 1 else: 0
      bitmap.setPixel(x, y, pixelValue)
  
  let bitmapData = getData(bitmap)
  let checksum = computeChecksum(bitmapData)
  
  doAssert checksum.len > 0, "Complex bitmap checksum should not be empty"
  doAssert checksum[0].isDigit() == true, "Complex bitmap checksum should start with a digit"
  
  when defined(VERBOSE_OUTPUT):
    echo fmt"Complex bitmap checksum: {checksum}"

# Test Checksum consistency across runs
block ChecksumConsistencyAcrossRuns:
  let bitmap1 = newJBIG2Bitmap(16, 16, 0)
  let bitmap2 = newJBIG2Bitmap(16, 16, 0)
  
  # Create identical patterns
  for x in 0..<16:
    for y in 0..<16:
      let pixelValue = if (x * y) mod 3 == 0: 1 else: 0
      bitmap1.setPixel(x, y, pixelValue)
      bitmap2.setPixel(x, y, pixelValue)
  
  let checksum1 = computeChecksum(getData(bitmap1))
  let checksum2 = computeChecksum(getData(bitmap2))
  
  # Identical patterns should produce identical checksums
  doAssert checksum1 == checksum2, "Identical bitmap patterns should produce identical checksums"

  # Test Checksum uniqueness for different patterns
block ChecksumUniquenessForDifferentPatterns:
  let bitmap1 = newJBIG2Bitmap(16, 16, 0)
  let bitmap2 = newJBIG2Bitmap(16, 16, 0)
  
  # Create different patterns
  for x in 0..<16:
    for y in 0..<16:
      bitmap1.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
      bitmap2.setPixel(x, y, if (x * y) mod 3 == 0: 1 else: 0)
  
  let checksum1 = computeChecksum(getData(bitmap1))
  let checksum2 = computeChecksum(getData(bitmap2))
  
  # Different patterns should produce different checksums
  doAssert checksum1 != checksum2, "Different bitmap patterns should produce different checksums"

# Test Checksum with different bitmap sizes
block ChecksumWithDifferentBitmapSizes:
  let sizes = [(8, 8), (16, 16), (32, 32), (64, 64)]
  var checksums: seq[string]
  
  for (width, height) in sizes:
    let bitmap = newJBIG2Bitmap(width, height, 0)
    
    # Create similar relative pattern
    for x in 0..<width:
      for y in 0..<height:
        bitmap.setPixel(x, y, if ((x div 2) + (y div 2)) mod 2 == 0: 1 else: 0)
    
    let checksum = computeChecksum(getData(bitmap))
    checksums.add(checksum)
  
  # Different sizes should produce different checksums
  for i in 0..<checksums.len - 1:
    for j in i + 1..<checksums.len:
      doAssert checksums[i] != checksums[j], fmt"Checksums for different sizes should be different: {i} vs {j}"

# Test Checksum with empty bitmap
block ChecksumWithEmptyBitmap:
  let bitmap = newJBIG2Bitmap(16, 16, 0)
  
  # Ensure all pixels are 0 (empty)
  bitmap.clear(0)
  
  let bitmapData = getData(bitmap)
  let checksum = computeChecksum(bitmapData)
  
  # Empty bitmap should have checksum of 0
  doAssert checksum == "0", "Empty bitmap should have checksum of 0"

# Test Checksum with full bitmap
block ChecksumWithFullBitmap:
  let bitmap = newJBIG2Bitmap(16, 16, 0)
  
  # Set all pixels to true
  for x in 0..<16:
    for y in 0..<16:
      bitmap.setPixel(x, y, 1)
  
  let bitmapData = getData(bitmap)
  let checksum = computeChecksum(bitmapData)
  
  # Full bitmap should have specific checksum (16*16 = 256 pixels)
  doAssert checksum.len > 0, "Full bitmap should have a checksum"
  doAssert checksum[0].isDigit() == true, "Checksum should start with a digit"

# Test Checksum performance with large bitmaps
block ChecksumPerformanceWithLargeBitmaps:
  when defined(PERFORMANCE_TESTING):
    let bitmap = newJBIG2Bitmap(256, 256, 0)
    
    # Create a pattern
    for x in 0..<256:
      for y in 0..<256:
        bitmap.setPixel(x, y, if (x xor y) mod 2 == 0: 1 else: 0)
    
    let startTime = epochTime()
    
    # Compute checksum multiple times
    var checksums: seq[string]
    for i in 0..<100:
      let checksum = computeChecksum(getData(bitmap))
      checksums.add(checksum)
    
    let endTime = epochTime()
    let executionTime = endTime - startTime
    
    # All checksums should be identical
    for i in 1..<checksums.len:
      doAssert checksums[i] == checksums[0], "Checksums for identical bitmap should be consistent"
    
    doAssert executionTime < 1.0, "100 checksum computations should complete within 1 second"
    
    when defined(VERBOSE_OUTPUT):
      echo fmt"Checksum performance: {executionTime:.3f}s for 100 computations on 256x256 bitmap"

# Test Checksum with bitmap data manipulation
block ChecksumWithBitmapDataManipulation:
  let bitmap = newJBIG2Bitmap(32, 32, 0)
  
  # Create initial pattern
  for x in 0..<32:
    for y in 0..<32:
      bitmap.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  let initialChecksum = computeChecksum(getData(bitmap))
  
  # Modify some pixels
  bitmap.setPixel(10, 10, 1)
  bitmap.setPixel(20, 20, 0)
  bitmap.setPixel(30, 30, 1)
  
  let modifiedChecksum = computeChecksum(getData(bitmap))
  
  # Checksum should change after modification
  doAssert initialChecksum != modifiedChecksum, "Checksum should change after bitmap modification"

# Test Checksum validation with known JBIG2 patterns
block ChecksumValidationWithKnownJBIG2Patterns:
  # Define pattern functions
  proc checkerboardPattern(x, y: int): int =
    return if (x + y) mod 2 == 0: 1 else: 0
  
  proc horizontalLinesPattern(x, y: int): int =
    return if y mod 4 == 0: 1 else: 0
  
  proc verticalLinesPattern(x, y: int): int =
    return if x mod 4 == 0: 1 else: 0
  
  proc diagonalLinesPattern(x, y: int): int =
    return if (x - y) mod 4 == 0: 1 else: 0
  
  proc circlesPattern(x, y: int): int =
    let cx = 16.0
    let cy = 16.0
    let r = 8.0
    let dist = sqrt(float((x - int(cx)) * (x - int(cx)) + (y - int(cy)) * (y - int(cy))))
    return if abs(dist - r) < 2.0: 1 else: 0
  
  let patterns = [
    ("checkerboard", checkerboardPattern),
    ("horizontal_lines", horizontalLinesPattern),
    ("vertical_lines", verticalLinesPattern),
    ("diagonal_lines", diagonalLinesPattern),
    ("circles", circlesPattern)
  ]
  
  for (patternName, patternFunc) in patterns:
    let bitmap = newJBIG2Bitmap(32, 32, 0)
    
    # Apply pattern
    for x in 0..<32:
      for y in 0..<32:
        bitmap.setPixel(x, y, patternFunc(x, y))
    
    let checksum = computeChecksum(getData(bitmap))
    
    doAssert checksum.len > 0, fmt"Pattern '{patternName}' checksum should not be empty"
    doAssert checksum[0].isDigit() == true, fmt"Pattern '{patternName}' checksum should start with a digit"

    when defined(VERBOSE_OUTPUT):
      echo fmt"Pattern '{patternName}' checksum: {checksum}"

# Test Checksum error handling
block ChecksumErrorHandling:
  # Test with empty data
  let emptyData = newSeq[byte](0)
  let emptyChecksum = computeChecksum(emptyData)
  
  doAssert emptyChecksum == "0", "Empty data should have checksum of 0"
  
  # Test with single byte
  let singleByteData = @[255'u8]
  let singleChecksum = computeChecksum(singleByteData)
  
  doAssert singleChecksum == "255", "Single byte 255 should have checksum of 255"
  
  # Test with large data
  var largeData = newSeq[byte](10000)
  for i in 0..<largeData.len:
    largeData[i] = (i mod 256).byte

  let largeChecksum = computeChecksum(largeData)

  doAssert largeChecksum.len > 0, "Large data checksum should not be empty"
  doAssert largeChecksum[0].isDigit() == true, "Large data checksum should start with a digit"
