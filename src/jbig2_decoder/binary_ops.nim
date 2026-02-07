## Binary operations utility for JBIG2 decoder

type
  BinaryOperation* = object

proc getInt32*(buffer: seq[byte]): int32 =
  ## Convert 4 bytes to a 32-bit integer (big-endian)
  if buffer.len < 4:
    raise newException(ValueError, "Buffer too small for 32-bit integer")
  result = (buffer[0].int32 shl 24) or (buffer[1].int32 shl 16) or 
           (buffer[2].int32 shl 8) or buffer[3].int32

proc getInt16*(buffer: seq[byte]): int16 =
  ## Convert 2 bytes to a 16-bit integer (big-endian)
  if buffer.len < 2:
    raise newException(ValueError, "Buffer too small for 16-bit integer")
  result = (buffer[0].int16 shl 8) or buffer[1].int16

proc getInt32LE*(buffer: seq[byte]): int32 =
  ## Convert 4 bytes to a 32-bit integer (little-endian)
  if buffer.len < 4:
    raise newException(ValueError, "Buffer too small for 32-bit integer")
  result = buffer[0].int32 or (buffer[1].int32 shl 8) or 
           (buffer[2].int32 shl 16) or (buffer[3].int32 shl 24)

proc getInt16LE*(buffer: seq[byte]): int16 =
  ## Convert 2 bytes to a 16-bit integer (little-endian)
  if buffer.len < 2:
    raise newException(ValueError, "Buffer too small for 16-bit integer")
  result = buffer[0].int16 or (buffer[1].int16 shl 8)

proc setBit*(value: int, bitPosition: int, bitValue: bool): int =
  ## Set a specific bit in an integer
  if bitValue:
    result = value or (1 shl bitPosition)
  else:
    result = value and not (1 shl bitPosition)

proc getBit*(value: int, bitPosition: int): bool =
  ## Get a specific bit from an integer
  result = (value and (1 shl bitPosition)) != 0

proc reverseBits*(value: byte): byte =
  ## Reverse the bits in a byte
  result = 0
  for i in 0..7:
    if (value and (1 shl i).byte) != 0:
      result = result or (1 shl (7 - i)).byte

proc countSetBits*(value: int): int =
  ## Count the number of set bits in an integer
  result = 0
  var temp = value
  while temp != 0:
    if (temp and 1) != 0:
      inc result
    temp = temp shr 1

proc countLeadingZeros*(value: int): int =
  ## Count leading zeros in a 32-bit integer
  if value == 0:
    return 32
  result = 0
  var temp = value
  while (temp and 0x80000000) == 0:
    inc result
    temp = temp shl 1

proc byteSwap*(value: int32): int32 =
  ## Swap bytes in a 32-bit integer
  let b0 = (value shr 24) and 0xFF
  let b1 = (value shr 16) and 0xFF
  let b2 = (value shr 8) and 0xFF
  let b3 = value and 0xFF
  result = (b3 shl 24) or (b2 shl 16) or (b1 shl 8) or b0

proc byteSwap*(value: int16): int16 =
  ## Swap bytes in a 16-bit integer
  let b0 = (value shr 8) and 0xFF
  let b1 = value and 0xFF
  result = int16((b1 shl 8) or b0)