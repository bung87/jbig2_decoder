## Forward declarations for stream decoder to avoid circular dependencies
import ./segment
import ./jbig2_bitmap
import ./stream_reader

type
  JBIG2StreamDecoderObj* = object
    ## Forward declaration for JBIG2StreamDecoder
    ## The actual implementation is in jbig2_stream_decoder.nim
    reader*: Big2StreamReader

  JBIG2StreamDecoder* = ref JBIG2StreamDecoderObj
  JBIG2StreamDecoderRef* = JBIG2StreamDecoder

# Forward declarations for methods that segments need to call
# These will be implemented in jbig2_stream_decoder.nim using method dispatch
method findSegment*(decoder: JBIG2StreamDecoder, segmentNumber: int): Segment {.base.} =
  ## Find a segment by its number
  return nil

method findPageSegment*(decoder: JBIG2StreamDecoder, pageAssociation: int): Segment {.base.} =
  ## Find a page segment by its page association
  return nil

method findBitmap*(decoder: JBIG2StreamDecoder, bitmapNumber: int): JBIG2Bitmap {.base.} =
  ## Find a bitmap by its number
  return nil

method appendBitmap*(decoder: JBIG2StreamDecoder, bitmap: JBIG2Bitmap) {.base.} =
  ## Append a bitmap to the decoder's bitmap list
  discard

method consumeRemainingBits*(decoder: JBIG2StreamDecoder) {.base.} =
  ## Consume any remaining bits in the current byte
  discard
