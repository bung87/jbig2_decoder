## End of Stripe Segment
import ../segment
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader

type
  EndOfStripeSegment* = ref object of Segment
    ## End of stripe segment
    reader*: Big2StreamReader

proc newEndOfStripeSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, reader: Big2StreamReader = nil): EndOfStripeSegment =
  ## Create a new end of stripe segment
  result = EndOfStripeSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    reader: reader
  )

method readSegment*(segment: EndOfStripeSegment) =
  ## Read end of stripe segment data
  # End of stripe segment has no data to read
  discard
