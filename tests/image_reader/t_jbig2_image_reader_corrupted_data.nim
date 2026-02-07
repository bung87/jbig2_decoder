discard """
exitcode: 1
"""

## JBIG2 image reader corrupted data exception test
import jbig2_decoder/jbig2_stream_decoder

# Test JBIG2ImageReader with corrupted data - should throw exception
let decoder = newJBIG2StreamDecoder()

# Create corrupted JBIG2 data
let corruptedData = @[
  0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8,  # Invalid header
  0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
]

# Should handle corrupted data gracefully
decoder.globalData = corruptedData

# This should throw an exception - don't use try-catch
discard decodeJBIG2(decoder, corruptedData)