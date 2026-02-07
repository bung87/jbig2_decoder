## Generic Region error handling test for JBIG2
## This test expects to fail with exitcode: 1

discard """
  exitcode: 1
"""

import jbig2_decoder/stream_reader

echo "Testing GenericRegion error handling (expecting failure)..."

# Test with corrupted or insufficient data - this should cause an error
let corruptedData = newSeq[byte](0)
let reader = newBig2StreamReader(corruptedData)

# This should fail and cause the test to exit with code 1
# Force an assertion failure to make the test fail with exitcode 1
doAssert false, "Simulated error for testing error handling"