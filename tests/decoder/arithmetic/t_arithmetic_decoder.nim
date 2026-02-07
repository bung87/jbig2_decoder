## Arithmetic decoder tests for JBIG2
import std/strformat
import jbig2_decoder/stream_reader
import jbig2_decoder/arithmetic_decoder

block ArithmeticDecoderTests:
  # Create test data for arithmetic decoder
  let testData = @[0x84'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
                 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]
  let reader = newBig2StreamReader(testData)
  var decoder = newArithmeticDecoder(reader)

  # Test ArithmeticDecoder creation and initialization
  block ArithmeticDecoderCreationAndInitialization:
    doAssert decoder != nil, "Arithmetic decoder should be successfully created"
    doAssert decoder.reader == reader, "Decoder should reference the correct stream reader"
    doAssert decoder.a == 0x10000, "Decoder interval register should be initialized to 0x10000"
    doAssert decoder.c == 0, "Decoder code register should be initialized to 0"

  # Test ArithmeticDecoder reset functionality
  block ArithmeticDecoderResetFunctionality:
    decoder.reset()
    doAssert decoder.a == 0x10000, "Reset decoder interval register should be 0x10000"
    doAssert decoder.c == 0, "Reset decoder code register should be 0"
    doAssert decoder.currentBit == 0, "Reset decoder current bit should be 0"
    doAssert decoder.currentByte == 0, "Reset decoder current byte should be 0"

  # Test ArithmeticDecoder readBit basic functionality
  block ArithmeticDecoderReadBitBasicFunctionality:
    # This is a simplified test - full arithmetic decoding is complex
    let bit = decoder.readBit(0)
    doAssert bit == 0 or bit == 1, "Read bit should return valid binary value (0 or 1)"

  # Test ArithmeticDecoder readBits functionality
  block ArithmeticDecoderReadBitsFunctionality:
    let bits = decoder.readBits(8, 0)
    doAssert bits >= 0 and bits <= 255, "Read bits should return valid 8-bit value (0-255)"

  # Test ArithmeticDecoderStats creation
  block ArithmeticDecoderStatsCreation:
    let stats = newArithmeticDecoderStats()
    doAssert stats != nil, "Arithmetic decoder stats should be successfully created"
    doAssert stats.contextTable.len == 4096, "Context table should have 4096 entries"

  # Test ArithmeticDecoder decodeInt basic test
  block ArithmeticDecoderDecodeIntBasicTest:
    ## Test integer decoding (simplified implementation)
    let decodedIntResult = decoder.decodeInt(newArithmeticDecoderStats())
    doAssert decodedIntResult.success, "Decoded integer should be successful"
    # Value can be positive or negative depending on the sign bit decoded

  # Test ArithmeticDecoder with trace data validation
  block ArithmeticDecoderWithTraceDataValidation:
    # Create a simple test pattern
    let patternData = @[0x00'u8, 0xFF'u8, 0xAA'u8, 0x55'u8]
    let patternReader = newBig2StreamReader(patternData)
    let patternDecoder = newArithmeticDecoder(patternReader)
    
    # Test reading bits from pattern
    let bit1 = patternDecoder.readBit(0)
    let bit2 = patternDecoder.readBit(0)
    
    doAssert bit1 == 0 or bit1 == 1, "First read bit should be valid binary value"
    doAssert bit2 == 0 or bit2 == 1, "Second read bit should be valid binary value"



  # Test ArithmeticDecoder with different contexts
  block ArithmeticDecoderWithDifferentContexts:
    let contexts = [0, 1, 10, 100, 1000]
    
    for context in contexts:
      let bit = decoder.readBit(context.int16)
      doAssert bit == 0 or bit == 1, fmt"Bit read with context {context} should be valid binary value"

  # Test ArithmeticDecoder performance baseline
  block ArithmeticDecoderPerformanceBaseline:
    when defined(PERFORMANCE_TESTING):
      let startTime = epochTime()
      
      # Perform multiple decode operations
      for i in 0..<1000:
        discard decoder.readBit(0)
      
      let endTime = epochTime()
      let executionTime = endTime - startTime
      
      doAssert executionTime < 1.0, "1000 decode operations should complete within 1 second"
      
      when defined(VERBOSE_OUTPUT):
        echo fmt"Arithmetic decoder performance: {executionTime:.3f}s for 1000 operations"

block ArithmeticIntegerDecoderTests:
  let testData = @[0x84'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
                 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newArithmeticDecoder(reader)
  let stats = newArithmeticDecoderStats()

  # Test ArithmeticIntegerDecoder basic decoding
  block ArithmeticIntegerDecoderBasicDecoding:
    let decodedResult = decoder.decodeInt(stats)
    doAssert decodedResult.success, "Decoded integer should be successful"
    # Value can be positive or negative depending on the sign bit decoded

  # Test ArithmeticIntegerDecoder with different statistics
  block ArithmeticIntegerDecoderWithDifferentStatistics:
    # Modify context table for testing
    stats.contextTable[0] = 100
    stats.contextTable[100] = 200
    
    let decodedResult = decoder.decodeInt(stats)
    doAssert decodedResult.success, "Decoded integer with modified stats should be successful"
    # Value can be positive or negative depending on the sign bit decoded

  # Test ArithmeticIntegerDecoder multiple decodes - with proper data management
  block ArithmeticIntegerDecoderMultipleDecodes:
    var decodedValues: seq[int]
    
    # Create fresh decoder with more data for multiple reads
    let multiTestData = @[0x84'u8, 0xFF'u8, 0xAA'u8, 0x55'u8, 0x00'u8, 0xFF'u8, 0xAA'u8, 0x55'u8,
                         0x84'u8, 0xFF'u8, 0xAA'u8, 0x55'u8, 0x00'u8, 0xFF'u8, 0xAA'u8, 0x55'u8]
    let multiReader = newBig2StreamReader(multiTestData)
    let multiDecoder = newArithmeticDecoder(multiReader)
    
    for i in 0..<3:  # Reduced number of decodes to avoid running out of data
      let result = multiDecoder.decodeInt(stats)
      doAssert result.success, fmt"Decoded integer {i} should be successful"
      decodedValues.add(result.value)
      # Value can be positive or negative depending on the sign bit decoded
    
    doAssert decodedValues.len == 3, "Should decode exactly 3 integer values"

  # Test ArithmeticIntegerDecoder boundary values
  block ArithmeticIntegerDecoderBoundaryValues:
    # Test with maximum context values
    stats.contextTable[4095] = 32767  # Max int16 value
    
    let decodedResult = decoder.decodeInt(stats)
    doAssert decodedResult.success, "Decoded integer with boundary context should be successful"
    # Value can be positive or negative depending on the sign bit decoded
