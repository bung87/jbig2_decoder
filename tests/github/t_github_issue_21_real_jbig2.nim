## GitHub Issue #21: Real JBIG2 file processing test
## This test uses actual JBIG2 files from the Java test resources

discard """
  disabled: true
  exitcode: 0
  output: "Issue #21 real JBIG2 processing test passed"
"""

import jbig2_decoder
import jbig2_decoder/jbig2_stream_decoder
import std/[os, streams]
import ../testdata/jbig2_test_config

proc loadTestResource(filename: string): seq[byte] =
  result = loadJBIG2GitHubFile(filename)
  

proc main() =
  ## Test for GitHub Issue #21 - real JBIG2 file processing
  
  # Load test data using the proper resource loader
  let testData = loadTestResource("21.jb2")
  let globalsData = loadTestResource("21.glob")
  

  # Test that we can load and process real JBIG2 files
  let decoder = newJBIG2StreamDecoder()
  

  let decodedData = decodeJBIG2(testData)
  doAssert decodedData.len > 0, "Decoded data should not be empty"

when isMainModule:
  main()