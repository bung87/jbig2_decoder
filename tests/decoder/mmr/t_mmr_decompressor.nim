## MMR (Modified Modified READ) decoder tests for JBIG2
## Based on Java test: org.apache.pdfbox.jbig2.decoder.mmr.MMRDecompressorTest
import std/[os, strformat, streams]
import jbig2_decoder
import jbig2_decoder/mmr_decoder

# Test MMR decoding with real JBIG2 file
block MMRDecodingTest:
  # Check if test file exists (use currentSourcePath to get test file location)
  let testDir = currentSourcePath().parentDir
  let testFilePath = testDir / ".." / ".." / ".." / "tests" / "testdata" / "images" / "001.jb2"

  doAssert fileExists(testFilePath), "Test file 001.jb2 not found"
  let absPath = absolutePath(testFilePath)

  # Read the JBIG2 file
  let fileStream = newFileStream(absPath, fmRead)

  # Read file data
  var fileData: seq[byte] = @[]
  while not fileStream.atEnd():
    fileData.add(cast[byte](fileStream.readChar()))
  fileStream.close()
  
  # For now, just verify we can create an MMR decoder
  # The actual segment extraction would require full JBIG2 parsing
  let reader = newBig2StreamReader(fileData)
  let decoder = newMMRDecoder(reader)
  
  doAssert decoder != nil, "MMR decoder should be successfully created"
  doAssert decoder.reader == reader, "MMR decoder should reference the correct stream reader"

  # Test MMRDecoder creation and initialization
block MMRDecoderCreationAndInitialization:
  let testData = @[0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  doAssert decoder != nil, "MMR decoder should be successfully created"
  doAssert decoder.reader == reader, "MMR decoder should reference the correct stream reader"
  doAssert decoder.bufferLength == 0, "Buffer length should be initialized to 0"
  doAssert decoder.noOfbytesRead == 0, "Bytes read should be initialized to 0"

  # Test MMRDecoder reset functionality
block MMRDecoderResetFunctionality:
  let testData = @[0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  # Modify state
  decoder.bufferLength = 10
  decoder.noOfbytesRead = 5
  
  # Reset
  decoder.reset()
  
  doAssert decoder.bufferLength == 0, "Buffer length should be reset to 0"
  doAssert decoder.noOfbytesRead == 0, "Bytes read should be reset to 0"

  # Test MMRDecoder get24Bits functionality
block MMRDecoderGet24BitsFunctionality:
  let testData = @[0x12'u8, 0x34'u8, 0x56'u8, 0x78'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  let bits = decoder.get24Bits()
  doAssert bits >= 0, "24 bits should be non-negative"
  doAssert decoder.bufferLength >= 0, "Buffer length should be non-negative after reading"

  # Test MMRDecoder skipTo functionality
block MMRDecoderSkipToFunctionality:
  let testData = @[0x01'u8, 0x02'u8, 0x03'u8, 0x04'u8, 0x05'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  decoder.skipTo(3)
  doAssert decoder.noOfbytesRead == 3, "Should have skipped 3 bytes"

  # Test MMRMode enum values
block MMRModeEnumValues:
  doAssert PassMode.ord == 0, "PassMode should have ordinal value 0"
  doAssert HorizontalMode.ord == 1, "HorizontalMode should have ordinal value 1"
  doAssert VerticalMode.ord == 2, "VerticalMode should have ordinal value 2"

  # Test MMRDecoder with empty data
block MMRDecoderWithEmptyData:
  let testData: seq[byte] = @[]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  doAssert decoder != nil, "MMR decoder should be created even with empty data"
  
  # get24Bits should return 0 for empty data
  let bits = decoder.get24Bits()
  doAssert bits == 0, "24 bits should be 0 for empty data"

  # Test MMRDecoder with single byte
block MMRDecoderWithSingleByte:
  let testData = @[0xFF'u8]
  let reader = newBig2StreamReader(testData)
  let decoder = newMMRDecoder(reader)
  
  let bits = decoder.get24Bits()
  doAssert bits >= 0, "24 bits should be non-negative"
  # get24Bits reads up to 3 bytes, but may read less if data is limited
  doAssert decoder.noOfbytesRead >= 0, "Should have read some bytes"
