## Stream reader for JBIG2 streams

type
  Big2StreamReader* = ref object
    data*: seq[byte]
    position*: int
    bitPosition*: int  # 0-7 for bit position within current byte

proc newBig2StreamReader*(data: seq[byte]): Big2StreamReader =
  ## Create a new stream reader
  result = Big2StreamReader(
    data: data,
    position: 0,
    bitPosition: 0
  )

proc isFinished*(reader: Big2StreamReader): bool =
  ## Check if we've reached the end of the stream
  result = reader.position >= reader.data.len

proc readByte*(reader: Big2StreamReader): byte =
  ## Read a single byte from the stream
  if reader.position >= reader.data.len:
    return 0  # Return 0 instead of raising exception for graceful handling
  result = reader.data[reader.position]
  inc reader.position

proc readByte*(reader: Big2StreamReader, buffer: var seq[byte]): bool =
  ## Read multiple bytes into a buffer, returns true if successful
  result = true
  for i in 0..<buffer.len:
    if reader.position >= reader.data.len:
      buffer[i] = 0  # Fill with zeros if we reach end of stream
      result = false  # Indicate that we couldn't read all data
    else:
      buffer[i] = reader.data[reader.position]
      inc reader.position

proc readBit*(reader: Big2StreamReader): int =
  ## Read a single bit from the stream
  if reader.bitPosition == 0:
    # Need to read a new byte
    if reader.position >= reader.data.len:
      return 0  # Return 0 instead of raising exception
    reader.bitPosition = 8
  
  dec reader.bitPosition
  result = int((reader.data[reader.position] shr reader.bitPosition) and 1)
  
  if reader.bitPosition == 0:
    inc reader.position
    reader.bitPosition = 0

proc readBits*(reader: Big2StreamReader, numBits: int): int =
  ## Read multiple bits from the stream
  result = 0
  for i in 0..<numBits:
    result = (result shl 1) or reader.readBit()

proc movePointer*(reader: Big2StreamReader, offset: int) =
  ## Move the stream pointer by the specified offset
  reader.position = max(0, min(reader.data.len, reader.position + offset))
  reader.bitPosition = 0

proc consumeRemainingBits*(reader: Big2StreamReader) =
  ## Consume any remaining bits in the current byte
  reader.bitPosition = 0

proc getPosition*(reader: Big2StreamReader): int =
  ## Get current position in the stream
  result = reader.position

proc setPosition*(reader: Big2StreamReader, position: int) =
  ## Set position in the stream
  reader.position = max(0, min(reader.data.len, position))
  reader.bitPosition = 0

proc readInt32*(reader: Big2StreamReader): int32 =
  ## Read a 32-bit integer from the stream (little-endian)
  var bytes: array[4, byte]
  for i in 0..3:
    bytes[i] = reader.readByte()
  result = cast[int32](bytes)