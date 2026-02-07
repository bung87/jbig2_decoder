discard """
exitcode: 1
outputsub: "InvalidHeaderValueError"
"""

## JBIG2 image reader global data exception test
import jbig2_decoder/jbig2_stream_decoder

# Test JBIG2ImageReader with global data - should throw exception with invalid data
let decoder = newJBIG2StreamDecoder()

# Create global data (typical for PDF embedded streams)
let globalData = @[
  0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8, 0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,  # Header
  0x00'u8,  # Flags
  0x00'u8, 0x00'u8, 0x00'u8, 0x01'u8,  # 1 page
]

let streamData = @[
  0x00'u8, 0x00'u8, 0x00'u8, 0x02'u8,  # Segment 2
  0x30'u8,  # Page Information
  0x00'u8,  # Flags
  0x01'u8,  # Page association
  0x00'u8, 0x00'u8, 0x00'u8, 0x20'u8,  # Data length
]

decoder.globalData = globalData

# Test decoding with global data - should throw exception with test data
discard decodeJBIG2(decoder, streamData)