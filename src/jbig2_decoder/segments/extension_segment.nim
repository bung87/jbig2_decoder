## Extension Segment
import ../segment
import ../arithmetic_decoder
import ../huffman_decoder
import ../mmr_decoder
import ../stream_reader
import ../binary_ops

type
  ExtensionSegment* = ref object of Segment
    ## Extension segment
    extensionFlags*: int
    reader*: Big2StreamReader

proc newExtensionSegment*(huffmanDecoder: HuffmanDecoder, arithmeticDecoder: ArithmeticDecoder, mmrDecoder: MMRDecoder, reader: Big2StreamReader = nil): ExtensionSegment =
  ## Create a new extension segment
  result = ExtensionSegment(
    huffmanDecoder: huffmanDecoder,
    arithmeticDecoder: arithmeticDecoder,
    mmrDecoder: mmrDecoder,
    extensionFlags: 0,
    reader: reader
  )

method readSegment*(segment: ExtensionSegment) =
  ## Read extension segment data
  if segment.reader != nil:
    # Read extension flags (2 bytes)
    var buff = newSeq[byte](2)
    for i in 0..<2:
      buff[i] = segment.reader.readByte()
    segment.extensionFlags = getInt16(buff).int

    # Read extension data length (4 bytes)
    buff = newSeq[byte](4)
    for i in 0..<4:
      buff[i] = segment.reader.readByte()
    let dataLength = getInt32(buff).int

    # Skip extension data
    for i in 0..<dataLength:
      discard segment.reader.readByte()
