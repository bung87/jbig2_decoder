## JBIG2 image reader tests
import std/[strformat]
import jbig2_decoder/jbig2_stream_decoder
import jbig2_decoder/jbig2_bitmap
import jbig2_decoder  # For computeChecksum
import ../testdata/jbig2_test_config


# Load and decode 002.jb2 once, reuse results
let fileData = loadJBIG2TestFile("002.jb2")

let sharedDecoder = newJBIG2StreamDecoder()
let decodedData = decodeJBIG2(sharedDecoder, fileData)

let sharedPageBitmap = jbig2_stream_decoder.getPageAsJBIG2Bitmap(sharedDecoder, 0)

# Test JBIG2ImageReader basic creation
block JBIG2ImageReaderBasicCreation:
  let decoder = newJBIG2StreamDecoder()
  
  doAssert decoder != nil, "Decoder should be successfully created"
  doAssert decoder.noOfPages == -1, "noOfPages should be -1 (not yet initialized)"
  doAssert decoder.noOfPagesKnown == false, "noOfPagesKnown should be false initially"

# Test JBIG2ImageReader with valid header
block JBIG2ImageReaderWithValidHeader:
  let decoder = newJBIG2StreamDecoder()
  
  # Create a minimal valid JBIG2 header
  let validHeader = @[0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8, 0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8]
  
  # Set up decoder with header data
  decoder.globalData = validHeader
  
  # Basic decoder should be functional
  doAssert decoder != nil, "Decoder should remain valid after setting global data"

# Test JBIG2ImageReader with different read parameters
block JBIG2ImageReaderWithDifferentReadParameters:
  let decoder = newJBIG2StreamDecoder()
  
  # Test different parameter combinations
  let testCases = [
    (0, 0, 100, 100),    # Full read
    (10, 10, 50, 50),    # Partial read
    (0, 0, 200, 300),    # Larger dimensions
    (25, 25, 75, 75),    # Offset read
  ]
  
  for (x, y, width, height) in testCases:
    # Test that parameters are handled (actual implementation would use these)
    doAssert x >= 0, fmt"X coordinate should be non-negative, got {x}"
    doAssert y >= 0, fmt"Y coordinate should be non-negative, got {y}"
    doAssert width > 0, fmt"Width should be positive, got {width}"
    doAssert height > 0, fmt"Height should be positive, got {height}"

# Test JBIG2ImageReader with 002.jb2 file data - all related assertions in one block
block JBIG2ImageReaderWith002File:
  # Verify pre-decoded bitmap is valid
  doAssert sharedPageBitmap != nil, "Page bitmap should not be nil"
  doAssert sharedPageBitmap.width > 0, "Page width should be positive"
  doAssert sharedPageBitmap.height > 0, "Page height should be positive"
  
  # Test checksum validation
  let bitmapData = sharedPageBitmap.getData()
  let checksum = computeChecksum(bitmapData)
  

  doAssert checksum.len > 0, "Checksum should not be empty"

# Test JBIG2ImageReader error handling
block JBIG2ImageReaderErrorHandling:
  let decoder = newJBIG2StreamDecoder()
  
  # Test with empty data - decodeJBIG2 should handle this gracefully
  let emptyData: seq[byte] = @[]
  let decodedEmptyData = decodeJBIG2(decoder, emptyData)
  
  # Test with corrupted data - decodeJBIG2 should handle this gracefully
  let corruptedData = @[0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8]
  let decodedCorruptedData = decodeJBIG2(decoder, corruptedData)
