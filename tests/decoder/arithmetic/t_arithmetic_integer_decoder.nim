## Arithmetic integer decoder tests for JBIG2
## Based on: org.apache.pdfbox.jbig2.decoder.arithmetic.ArithmeticIntegerDecoderTest
import std/strformat
import jbig2_decoder
import jbig2_decoder/arithmetic_decoder
import ../../testdata/jbig2_test_config


block DecodeTest:

  let testData = loadArithmeticTestData("encoded_testsequence.bin")
  doAssert testData.len > 0, "Should load test resource file successfully"
  
  let reader = newBig2StreamReader(testData)
  
  let ad = newArithmeticDecoder(reader)
  ad.start()
  
  let aid = newArithmeticIntegerDecoder(ad)

  let result = aid.decode(nil)
  
  doAssert result == 1, fmt"Decoded value should be 1, got {result}"

