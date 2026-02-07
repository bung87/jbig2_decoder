## Page Information error handling test for JBIG2
## This test expects to fail with exitcode: 1

discard """
  disabled: true
  exitcode: 1
"""

import jbig2_decoder/stream_reader


# Test with empty data - this should cause an error
let emptyData = newSeq[byte](0)
let emptyReader = newBig2StreamReader(emptyData)

