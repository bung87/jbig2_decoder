## Region Segment Information tests - matches Java RegionSegmentInformationTest.java logic
import std/[os, strformat]
import jbig2_decoder/segment_factory
import jbig2_decoder/stream_reader


# Test parseHeader - matches Java test logic

# Test with manually constructed header data
block ParseHeaderManualTest:
  # Construct a region segment information header (17 bytes)
  # Format: width(4) + height(4) + xLocation(4) + yLocation(4) + flags(1)
  var headerData = newSeq[byte](17)

  # Bitmap width = 100 (0x00000064 in big-endian)
  headerData[0] = 0x00
  headerData[1] = 0x00
  headerData[2] = 0x00
  headerData[3] = 0x64

  # Bitmap height = 50 (0x00000032 in big-endian)
  headerData[4] = 0x00
  headerData[5] = 0x00
  headerData[6] = 0x00
  headerData[7] = 0x32

  # X location = 10 (0x0000000A in big-endian)
  headerData[8] = 0x00
  headerData[9] = 0x00
  headerData[10] = 0x00
  headerData[11] = 0x0A

  # Y location = 20 (0x00000014 in big-endian)
  headerData[12] = 0x00
  headerData[13] = 0x00
  headerData[14] = 0x00
  headerData[15] = 0x14

  # Region flags: combination operator = OR (0)
  headerData[16] = 0x00

  let reader = newBig2StreamReader(headerData)
  let rsi = newRegionSegmentInformation(reader)
  rsi.parseHeader()

  doAssert rsi.bitmapWidth == 100, fmt"Expected bitmapWidth=100, got {rsi.bitmapWidth}"
  doAssert rsi.bitmapHeight == 50, fmt"Expected bitmapHeight=50, got {rsi.bitmapHeight}"
  doAssert rsi.xLocation == 10, fmt"Expected xLocation=10, got {rsi.xLocation}"
  doAssert rsi.yLocation == 20, fmt"Expected yLocation=20, got {rsi.yLocation}"
  doAssert rsi.combinationOperator == coOr, fmt"Expected combinationOperator=coOr, got {rsi.combinationOperator}"

# Test all combination operators
block CombinationOperatorsTest:
  let testCases = [
    (0, coOr),
    (1, coAnd),
    (2, coXor),
    (3, coXnor),
    (4, coReplace)
  ]

  for (flagValue, expectedOp) in testCases:
    var headerData = newSeq[byte](17)

    # Set minimal valid header
    headerData[0] = 0x00; headerData[1] = 0x00; headerData[2] = 0x00; headerData[3] = 0x01  # width=1
    headerData[4] = 0x00; headerData[5] = 0x00; headerData[6] = 0x00; headerData[7] = 0x01  # height=1
    headerData[8] = 0x00; headerData[9] = 0x00; headerData[10] = 0x00; headerData[11] = 0x00 # x=0
    headerData[12] = 0x00; headerData[13] = 0x00; headerData[14] = 0x00; headerData[15] = 0x00 # y=0
    headerData[16] = flagValue.byte  # combination operator

    let reader = newBig2StreamReader(headerData)
    let rsi = newRegionSegmentInformation(reader)
    rsi.parseHeader()

    doAssert rsi.combinationOperator == expectedOp,
      fmt"For flag value {flagValue}, expected {expectedOp}, got {rsi.combinationOperator}"

# Test default to OR for unknown operator values
block UnknownOperatorTest:
  var headerData = newSeq[byte](17)

  # Set minimal valid header
  headerData[0] = 0x00; headerData[1] = 0x00; headerData[2] = 0x00; headerData[3] = 0x01  # width=1
  headerData[4] = 0x00; headerData[5] = 0x00; headerData[6] = 0x00; headerData[7] = 0x01  # height=1
  headerData[8] = 0x00; headerData[9] = 0x00; headerData[10] = 0x00; headerData[11] = 0x00 # x=0
  headerData[12] = 0x00; headerData[13] = 0x00; headerData[14] = 0x00; headerData[15] = 0x00 # y=0
  headerData[16] = 0x07  # Unknown operator value (7)

  let reader = newBig2StreamReader(headerData)
  let rsi = newRegionSegmentInformation(reader)
  rsi.parseHeader()

  doAssert rsi.combinationOperator == coOr,
    fmt"Unknown operator should default to coOr, got {rsi.combinationOperator}"

# Test with negative coordinates (signed values)
block NegativeCoordinatesTest:
  var headerData = newSeq[byte](17)

  # Width = 10
  headerData[0] = 0x00; headerData[1] = 0x00; headerData[2] = 0x00; headerData[3] = 0x0A

  # Height = 10
  headerData[4] = 0x00; headerData[5] = 0x00; headerData[6] = 0x00; headerData[7] = 0x0A

  # X location = -5 (0xFFFFFFFB in big-endian two's complement)
  headerData[8] = 0xFF; headerData[9] = 0xFF; headerData[10] = 0xFF; headerData[11] = 0xFB

  # Y location = -10 (0xFFFFFFF6 in big-endian two's complement)
  headerData[12] = 0xFF; headerData[13] = 0xFF; headerData[14] = 0xFF; headerData[15] = 0xF6

  # Flags
  headerData[16] = 0x00

  let reader = newBig2StreamReader(headerData)
  let rsi = newRegionSegmentInformation(reader)
  rsi.parseHeader()

  doAssert rsi.bitmapWidth == 10
  doAssert rsi.bitmapHeight == 10
  doAssert rsi.xLocation == -5, fmt"Expected xLocation=-5, got {rsi.xLocation}"
  doAssert rsi.yLocation == -10, fmt"Expected yLocation=-10, got {rsi.yLocation}"
