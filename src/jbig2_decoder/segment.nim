## Base segment class for JBIG2 segments
import ./segment_header
import ./arithmetic_decoder
import ./huffman_decoder
import ./mmr_decoder

# Segment type constants for internal use
const
  SEG_SYMBOL_DICTIONARY* = 0
  SEG_INTERMEDIATE_TEXT_REGION* = 4
  SEG_IMMEDIATE_TEXT_REGION* = 6
  SEG_IMMEDIATE_LOSSLESS_TEXT_REGION* = 7
  SEG_PATTERN_DICTIONARY* = 16
  SEG_INTERMEDIATE_HALFTONE_REGION* = 20
  SEG_IMMEDIATE_HALFTONE_REGION* = 22
  SEG_IMMEDIATE_LOSSLESS_HALFTONE_REGION* = 23
  SEG_INTERMEDIATE_GENERIC_REGION* = 36
  SEG_IMMEDIATE_GENERIC_REGION* = 38
  SEG_IMMEDIATE_LOSSLESS_GENERIC_REGION* = 39
  SEG_INTERMEDIATE_GENERIC_REFINEMENT_REGION* = 40
  SEG_IMMEDIATE_GENERIC_REFINEMENT_REGION* = 42
  SEG_IMMEDIATE_LOSSLESS_GENERIC_REFINEMENT_REGION* = 43
  SEG_PAGE_INFORMATION* = 48
  SEG_END_OF_PAGE* = 49
  SEG_END_OF_STRIPE* = 50
  SEG_END_OF_FILE* = 51
  SEG_PROFILES* = 52
  SEG_TABLES* = 53
  SEG_EXTENSION* = 62
  SEG_BITMAP* = 70

type
  Segment* = ref object of RootObj
    segmentHeader*: segment_header.SegmentHeader
    huffmanDecoder*: huffman_decoder.HuffmanDecoder
    arithmeticDecoder*: arithmetic_decoder.ArithmeticDecoder
    mmrDecoder*: mmr_decoder.MMRDecoder

proc newSegment*(): Segment =
  ## Create a new segment
  result = Segment()

# proc readATValue*(segment: Segment): int16 =
#   ## Read AT (adaptive template) value
#   let c0 = segment.decoder.readByte()
#   result = c0.int16
#   
#   if (c0 and 0x80) != 0:
#     result = result or -1 - 0xFF

proc getSegmentHeader*(segment: Segment): segment_header.SegmentHeader =
  ## Get segment header
  result = segment.segmentHeader

proc setSegmentHeader*(segment: Segment, header: segment_header.SegmentHeader) =
  ## Set segment header
  segment.segmentHeader = header

method readSegment*(segment: Segment) {.base.} =
  ## Default implementation - does nothing, to be overridden by subclasses
  # This default implementation allows segments to work without raising exceptions
  discard

# Segment type names for debugging
proc getSegmentTypeName*(segmentType: int): string =
  ## Get human-readable name for segment type
  case segmentType
  of SEG_SYMBOL_DICTIONARY: "Symbol Dictionary"
  of SEG_INTERMEDIATE_TEXT_REGION: "Intermediate Text Region"
  of SEG_IMMEDIATE_TEXT_REGION: "Immediate Text Region"
  of SEG_IMMEDIATE_LOSSLESS_TEXT_REGION: "Immediate Lossless Text Region"
  of SEG_PATTERN_DICTIONARY: "Pattern Dictionary"
  of SEG_INTERMEDIATE_HALFTONE_REGION: "Intermediate Halftone Region"
  of SEG_IMMEDIATE_HALFTONE_REGION: "Immediate Halftone Region"
  of SEG_IMMEDIATE_LOSSLESS_HALFTONE_REGION: "Immediate Lossless Halftone Region"
  of SEG_INTERMEDIATE_GENERIC_REGION: "Intermediate Generic Region"
  of SEG_IMMEDIATE_GENERIC_REGION: "Immediate Generic Region"
  of SEG_IMMEDIATE_LOSSLESS_GENERIC_REGION: "Immediate Lossless Generic Region"
  of SEG_INTERMEDIATE_GENERIC_REFINEMENT_REGION: "Intermediate Generic Refinement Region"
  of SEG_IMMEDIATE_GENERIC_REFINEMENT_REGION: "Immediate Generic Refinement Region"
  of SEG_IMMEDIATE_LOSSLESS_GENERIC_REFINEMENT_REGION: "Immediate Lossless Generic Refinement Region"
  of SEG_PAGE_INFORMATION: "Page Information"
  of SEG_END_OF_PAGE: "End of Page"
  of SEG_END_OF_STRIPE: "End of Stripe"
  of SEG_END_OF_FILE: "End of File"
  of SEG_PROFILES: "Profiles"
  of SEG_TABLES: "Tables"
  of SEG_EXTENSION: "Extension"
  of SEG_BITMAP: "Bitmap"
  else: "Unknown Segment Type (" & $segmentType & ")"