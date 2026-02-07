## Segment header for JBIG2 segments

type
  SegmentHeader* = ref object
    segmentNumber*: int
    segmentType*: int
    pageAssociationSizeSet*: bool
    deferredNonRetainSet*: bool
    referredToSegmentCount*: int
    retentionFlags*: seq[byte]
    referredToSegments*: seq[int]
    pageAssociation*: int
    dataLength*: int

proc newSegmentHeader*(): SegmentHeader =
  ## Create a new segment header
  result = SegmentHeader()

proc setSegmentHeaderFlags*(header: SegmentHeader, flags: byte) =
  ## Parse and set segment header flags from a single byte
  header.segmentType = int(flags and 0x3F)  # 00111111
  header.pageAssociationSizeSet = (flags and 0x40) != 0  # 01000000
  header.deferredNonRetainSet = (flags and 0x80) != 0  # 10000000