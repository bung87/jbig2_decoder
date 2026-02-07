## Base segment types and common definitions
import ../stream_reader
import ../binary_ops

## Combination operator values for region segments
type
  CombinationOperator* = enum
    coOr = 0      ## OR operation
    coAnd = 1     ## AND operation
    coXor = 2     ## XOR operation
    coXnor = 3    ## XNOR operation
    coReplace = 4 ## REPLACE operation

  RegionSegmentInformation* = ref object
    ## Region segment information - parses region header data
    bitmapWidth*: int
    bitmapHeight*: int
    xLocation*: int
    yLocation*: int
    combinationOperator*: CombinationOperator
    reader*: Big2StreamReader

# RegionSegmentInformation factory and methods
proc newRegionSegmentInformation*(reader: Big2StreamReader = nil): RegionSegmentInformation =
  ## Create a new region segment information object
  result = RegionSegmentInformation(
    bitmapWidth: 0,
    bitmapHeight: 0,
    xLocation: 0,
    yLocation: 0,
    combinationOperator: coOr,
    reader: reader
  )

proc parseHeader*(rsi: RegionSegmentInformation) =
  ## Parse the region segment information header from the stream
  if rsi.reader == nil:
    raise newException(ValueError, "No stream reader available")

  var buff = newSeq[byte](4)

  # Read bitmap width (4 bytes, big-endian)
  for i in 0..<4:
    buff[i] = rsi.reader.readByte()
  rsi.bitmapWidth = getInt32(buff).int

  # Read bitmap height (4 bytes, big-endian)
  for i in 0..<4:
    buff[i] = rsi.reader.readByte()
  rsi.bitmapHeight = getInt32(buff).int

  # Read X location (4 bytes, big-endian)
  for i in 0..<4:
    buff[i] = rsi.reader.readByte()
  rsi.xLocation = getInt32(buff).int

  # Read Y location (4 bytes, big-endian)
  for i in 0..<4:
    buff[i] = rsi.reader.readByte()
  rsi.yLocation = getInt32(buff).int

  # Read region flags (1 byte)
  let flags = rsi.reader.readByte().int
  let opValue = flags and 0x07
  rsi.combinationOperator = case opValue
    of 0: coOr
    of 1: coAnd
    of 2: coXor
    of 3: coXnor
    of 4: coReplace
    else: coOr
