## JBIG2Bitmap blitting tests
import std/[os, strformat]
import jbig2_decoder/jbig2_bitmap



# Test basic blitting
block BasicBlitting:
  echo "  Testing basic bitmap blitting..."
  let source = newJBIG2Bitmap(10, 10, 0)
  let destination = newJBIG2Bitmap(20, 20, 0)
  
  # Create a pattern in source bitmap
  for x in 0..<10:
    for y in 0..<10:
      source.setPixel(x, y, if (x + y) mod 2 == 0: 1 else: 0)
  
  # Blit source to destination at position (10, 10) using OR operator
  destination.combine(source, 10, 10, 0)
  
  # Verify the transfer
  for x in 0..<10:
    for y in 0..<10:
      doAssert destination.getPixel(10 + x, 10 + y) == source.getPixel(x, y), "Blitted pixels should match source"
  
  echo "    ✓ Basic blitting passed"

# Test blitting with different positions
block BlittingPositions:
  echo "  Testing blitting at different positions..."
  let source = newJBIG2Bitmap(5, 5, 0)
  let destination = newJBIG2Bitmap(15, 15, 0)
  
  # Fill source with true
  for x in 0..<5:
    for y in 0..<5:
      source.setPixel(x, y, 1)
  
  # Test different positions
  let positions = [(0, 0), (5, 5), (10, 10)]
  
  for (offsetX, offsetY) in positions:
    destination.clear(0)
    destination.combine(source, offsetX, offsetY, 0)
    
    # Verify transfer at correct position
    var transferredPixels = 0
    for x in 0..<5:
      for y in 0..<5:
        if destination.getPixel(offsetX + x, offsetY + y) != 0:
          transferredPixels.inc()
    
    doAssert transferredPixels == 25, "All 25 pixels should be transferred"
  
  echo "    ✓ Blitting at different positions passed"

# Test blitting with partial overlap
block PartialOverlapBlitting:
  echo "  Testing partial overlap blitting..."
  let source = newJBIG2Bitmap(10, 10, 0)
  let destination = newJBIG2Bitmap(10, 10, 0)
  
  # Fill source with a pattern
  for x in 0..<10:
    for y in 0..<10:
      source.setPixel(x, y, if x mod 2 == 0: 1 else: 0)
  
  # Blit with partial overlap (source extends beyond destination)
  destination.combine(source, 5, 5, 0)
  
  # Verify only overlapping area was transferred
  for x in 0..<10:
    for y in 0..<10:
      if x >= 5 and y >= 5:
        doAssert destination.getPixel(x, y) == source.getPixel(x - 5, y - 5), "Overlapping area should match"
      else:
        doAssert destination.getPixel(x, y) == 0, "Non-overlapping area should remain 0"
  
  echo "    ✓ Partial overlap blitting passed"

# Test blitting with negative offsets
block NegativeOffsetBlitting:
  echo "  Testing negative offset blitting..."
  let source = newJBIG2Bitmap(5, 5, 0)
  let destination = newJBIG2Bitmap(10, 10, 0)
  
  # Fill source with true
  for x in 0..<5:
    for y in 0..<5:
      source.setPixel(x, y, 1)
  
  # Blit with negative offset (-2, -2)
  # Source pixels at (2,2) and beyond will be visible at destination (0,0) and beyond
  destination.combine(source, -2, -2, 0)
  
  # Verify only visible portion was transferred
  # With offset (-2, -2), source (2,2) -> dest (0,0), source (4,4) -> dest (2,2)
  # So visible portion is x in [0, 3) and y in [0, 3)
  for x in 0..<10:
    for y in 0..<10:
      if x >= 0 and x < 3 and y >= 0 and y < 3:
        doAssert destination.getPixel(x, y) == 1, "Visible portion at (" & $x & "," & $y & ") should be 1"
      else:
        doAssert destination.getPixel(x, y) == 0, "Hidden portion at (" & $x & "," & $y & ") should be 0"
  
  echo "    ✓ Negative offset blitting passed"

echo "All Bitmap Blitting Tests passed!"
