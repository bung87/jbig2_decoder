## Pattern Dictionary Segment tests
import std/[os, strformat]
import jbig2_decoder/jbig2_bitmap

block PatternDictionaryTests:
  # Test basic pattern dictionary operations
  block BasicPatternDictionary:
    # Create several pattern bitmaps
    let pattern1 = newJBIG2Bitmap(8, 8, 0)
    let pattern2 = newJBIG2Bitmap(8, 8, 1)
    let pattern3 = newJBIG2Bitmap(8, 8, 2)
    
    # Fill patterns with different designs
    for x in 0..<8:
      for y in 0..<8:
        pattern1.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)  # Checkerboard
        pattern2.setPixel(x, y, if x == y: 1 else: 0)              # Diagonal
        pattern3.setPixel(x, y, if x < 4 and y < 4: 1 else: 0)     # Top-left quadrant
    
    # Verify patterns are different
    var differences = 0
    for x in 0..<8:
      for y in 0..<8:
        if pattern1.getPixel(x, y) != pattern2.getPixel(x, y):
          differences.inc()
    
    doAssert differences > 0, "Patterns should be different"

  # Test pattern dictionary with different sizes
  block PatternDictionarySizes:
    # Create patterns of different sizes
    let smallPattern = newJBIG2Bitmap(4, 4, 0)
    let mediumPattern = newJBIG2Bitmap(8, 8, 1)
    let largePattern = newJBIG2Bitmap(16, 16, 2)
    
    # Fill with recognizable patterns
    for x in 0..<smallPattern.width:
      for y in 0..<smallPattern.height:
        smallPattern.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
    
    for x in 0..<mediumPattern.width:
      for y in 0..<mediumPattern.height:
        mediumPattern.setPixel(x, y, if x == y or x + y == 7: 1 else: 0)
    
    for x in 0..<largePattern.width:
      for y in 0..<largePattern.height:
        largePattern.setPixel(x, y, if x < 8 and y < 8: 1 else: 0)
    
    # Verify dimensions
    doAssert smallPattern.width == 4 and smallPattern.height == 4
    doAssert mediumPattern.width == 8 and mediumPattern.height == 8
    doAssert largePattern.width == 16 and largePattern.height == 16
