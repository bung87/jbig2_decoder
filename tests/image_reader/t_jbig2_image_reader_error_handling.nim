discard """
exitcode: 1
outputsub: "InvalidHeaderValueError"
"""

## JBIG2 image reader real files exception test
import jbig2_decoder/jbig2_stream_decoder
import ../testdata/jbig2_test_config
import jbig2_decoder/jbig2_bitmap

# Test JBIG2ImageReader with invalid JBIG2 data - should throw exception
let decoder = newJBIG2StreamDecoder()

# Create invalid JBIG2 data with reserved bits set in header flags
var invalidData = @[
  0x97'u8, 0x4A, 0x42, 0x32, 0x0D, 0x0A, 0x1A, 0x0A,  # Valid ID string
  0xFC'u8  # Invalid flags: reserved bits 2-7 are set
]

let decodedData = decodeJBIG2(decoder, invalidData)

# This should throw InvalidHeaderValueError exception
let sharedPageBitmap = jbig2_stream_decoder.getPageAsJBIG2Bitmap(decoder, 0)
