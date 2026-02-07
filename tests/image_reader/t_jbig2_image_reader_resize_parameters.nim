discard """
exitcode: 1
outputsub: "InvalidHeaderValueError"
"""

## JBIG2 image reader resize parameters exception test
import jbig2_decoder/jbig2_stream_decoder
import jbig2_decoder/jbig2_types

# Test JBIG2ImageReader with resize parameters - should throw exception with invalid data
let decoder = newJBIG2StreamDecoder()

let testData = @[0x84'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
                 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]

# Test with resize parameters - should throw exception with test data
discard decodeJBIG2(decoder, testData, TIFF, 100, 100)