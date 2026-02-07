discard """
exitcode: 1
"""

## JBIG2 image reader different image formats exception test
import jbig2_decoder/jbig2_stream_decoder
import jbig2_decoder/jbig2_types

# Test JBIG2ImageReader with different image formats - should throw exception with invalid data
let decoder = newJBIG2StreamDecoder()

# Test data for different formats that should cause exception
let testData = @[0x84'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
                 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]

# Test TIFF format - should throw exception with test data
discard decodeJBIG2(decoder, testData, TIFF)