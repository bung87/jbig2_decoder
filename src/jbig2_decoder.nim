## JBig2Decoder - A JBIG2 image decoder library for Nim
##
## This library provides functionality to decode JBIG2 compressed images,
## commonly used in PDF documents and fax transmissions.

# Import the core types and stream decoder module
import jbig2_decoder/jbig2_types
import jbig2_decoder/jbig2_stream_decoder
import jbig2_decoder/stream_reader
import jbig2_decoder/jbig2_bitmap

export jbig2_types
export jbig2_stream_decoder
export stream_reader
export jbig2_bitmap

# Performance testing flags
const PERFORMANCE_TESTING* = defined(performance)
const VERBOSE_OUTPUT* = defined(verbose)

# Convenience wrapper for simple decoding - this is the only unique functionality
# that provides a simplified interface for users who don't need the full decoder
proc decodeJBIG2*(data: seq[byte], format: ImageFormat = TIFF, newWidth: int = 0, newHeight: int = 0): seq[byte] =
  ## Decode JBIG2 compressed image data with a simple interface
  ##
  ## Parameters:
  ##   data - The JBIG2 compressed image data
  ##   format - Output format (JPEG or TIFF)
  ##   newWidth - Optional width for resizing (0 means no resize)
  ##   newHeight - Optional height for resizing (0 means no resize)
  ##
  ## Returns:
  ##   Decoded image data in the specified format
  let decoder = newJBIG2StreamDecoder()
  result = decoder.decodeJBIG2(data, format, newWidth, newHeight)

# Utility functions that provide additional value beyond simple delegation

proc computeChecksum*(data: seq[byte]): string =
  ## Compute a simple checksum for bitmap data
  var sum: uint32 = 0
  for b in data:
    sum = sum + uint32(b)
  result = $sum

# Essential segment type constants for user convenience
const
  SYMBOL_DICTIONARY* = 0
  TEXT_REGION* = 6
  HALFTONE_REGION* = 7
  GENERIC_REGION* = 8
  GENERIC_REFINEMENT_REGION* = 9
  PAGE_INFORMATION* = 16
  END_OF_FILE* = 17
  PAGE_BITMAP* = 62
  END_OF_PAGE* = 63

# Test data generators for testing decoders
proc generateArithmeticTestSequence*(): seq[byte] =
  ## Generate test data for arithmetic decoder
  result = @[0x84'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
             0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]

proc generateMMRTestSequence*(): seq[byte] =
  ## Generate test data for MMR decoder
  result = @[0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]

proc generateHuffmanTestSequence*(): seq[byte] =
  ## Generate test data for Huffman decoder
  result = @[0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8]