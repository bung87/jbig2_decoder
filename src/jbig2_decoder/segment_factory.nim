## Segment factory for creating appropriate segment types
import ./segment
import ./jbig2_bitmap
import ./segment_header
import ./arithmetic_decoder
import ./huffman_decoder
import ./mmr_decoder
import ./stream_reader
import ./binary_ops
import ./stream_decoder_types

# Import segment types from segments directory
import ./segments/segment_types
import ./segments/symbol_dictionary_segment
import ./segments/text_region_segment
import ./segments/pattern_dictionary_segment
import ./segments/halftone_region_segment
import ./segments/generic_region_segment
import ./segments/refinement_region_segment
import ./segments/page_information_segment
import ./segments/end_of_stripe_segment
import ./segments/extension_segment

# Re-export all segment types
export segment_types
export symbol_dictionary_segment
export text_region_segment
export pattern_dictionary_segment
export halftone_region_segment
export generic_region_segment
export refinement_region_segment
export page_information_segment
export end_of_stripe_segment
export extension_segment
export stream_decoder_types

proc createSegment*(segmentType: int, huffmanDecoder: HuffmanDecoder = nil, arithmeticDecoder: ArithmeticDecoder = nil, mmrDecoder: MMRDecoder = nil, reader: Big2StreamReader = nil, streamDecoder: JBIG2StreamDecoderRef = nil): Segment =
  ## Factory function to create appropriate segment type based on segment type
  case segmentType
  of SEG_SYMBOL_DICTIONARY:
    result = newSymbolDictionarySegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, reader, streamDecoder)
  of SEG_INTERMEDIATE_TEXT_REGION, SEG_IMMEDIATE_TEXT_REGION, SEG_IMMEDIATE_LOSSLESS_TEXT_REGION:
    let immediate = (segmentType == SEG_IMMEDIATE_TEXT_REGION) or (segmentType == SEG_IMMEDIATE_LOSSLESS_TEXT_REGION)
    result = newTextRegionSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, immediate, reader)
  of SEG_PATTERN_DICTIONARY:
    result = newPatternDictionarySegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, reader)
  of SEG_INTERMEDIATE_HALFTONE_REGION, SEG_IMMEDIATE_HALFTONE_REGION, SEG_IMMEDIATE_LOSSLESS_HALFTONE_REGION:
    let immediate = (segmentType == SEG_IMMEDIATE_HALFTONE_REGION) or (segmentType == SEG_IMMEDIATE_LOSSLESS_HALFTONE_REGION)
    result = newHalftoneRegionSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, immediate, reader)
  of SEG_INTERMEDIATE_GENERIC_REGION, SEG_IMMEDIATE_GENERIC_REGION, SEG_IMMEDIATE_LOSSLESS_GENERIC_REGION:
    let immediate = (segmentType == SEG_IMMEDIATE_GENERIC_REGION) or (segmentType == SEG_IMMEDIATE_LOSSLESS_GENERIC_REGION)
    result = newGenericRegionSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, immediate, reader, streamDecoder)
  of SEG_INTERMEDIATE_GENERIC_REFINEMENT_REGION, SEG_IMMEDIATE_GENERIC_REFINEMENT_REGION, SEG_IMMEDIATE_LOSSLESS_GENERIC_REFINEMENT_REGION:
    let immediate = (segmentType == SEG_IMMEDIATE_GENERIC_REFINEMENT_REGION) or (segmentType == SEG_IMMEDIATE_LOSSLESS_GENERIC_REFINEMENT_REGION)
    result = newRefinementRegionSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, immediate, @[], 0, reader)
  of SEG_PAGE_INFORMATION:
    result = newPageInformationSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, reader)
  of SEG_END_OF_STRIPE:
    result = newEndOfStripeSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, reader)
  of SEG_EXTENSION:
    result = newExtensionSegment(huffmanDecoder, arithmeticDecoder, mmrDecoder, reader)
  else:
    # Default to base segment
    result = newSegment()
