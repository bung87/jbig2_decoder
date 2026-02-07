## Arithmetic decoder for JBIG2 - Exact match to C# reference implementation
import ./stream_reader

type
  DecodeIntResult* = object
    value*: int
    success*: bool

  ArithmeticDecoderStats* = ref object
    contextSize*: int
    codingContextTable*: seq[int]
    contextTable*: seq[int]  # Alias for compatibility with tests

  ArithmeticDecoder* = ref object
    reader*: Big2StreamReader
    genericRegionStats*: ArithmeticDecoderStats
    refinementRegionStats*: ArithmeticDecoderStats
    iadhStats*, iadwStats*, iaexStats*, iaaiStats*, iadtStats*, iaitStats*: ArithmeticDecoderStats
    iafsStats*, iadsStats*, iardxStats*, iardyStats*, iardwStats*, iardhStats*: ArithmeticDecoderStats
    iariStats*, iaidStats*: ArithmeticDecoderStats
    buffer0*, buffer1*: int64
    c*, a*, previous*: int64
    counter*: int
    currentBit*: int
    currentByte*: int

# Context size constants
const
  genericRegionContextSize* = 1 shl 1
  refinementRegionContextSize* = 1 shl 1

# Context size arrays matching C# reference implementation
# contextSize is used for generic region decoding (templates 0-3)
# referredToContextSize is used for refinement region decoding (templates 0-1)
let contextSize* = @[16, 13, 10, 10]
let referredToContextSize* = @[13, 10]

# QM-Coder state tables - exactly matching C# reference
# QE table with 47 entries (32-bit values shifted left by 16)
const qeTable = [
  0x56010000, 0x34010000, 0x18010000, 0x0AC10000, 0x05210000, 0x02210000,
  0x56010000, 0x54010000, 0x48010000, 0x38010000, 0x30010000, 0x24010000,
  0x1C010000, 0x16010000, 0x56010000, 0x54010000, 0x51010000, 0x48010000,
  0x38010000, 0x34010000, 0x30010000, 0x28010000, 0x24010000, 0x22010000,
  0x1C010000, 0x18010000, 0x16010000, 0x14010000, 0x12010000, 0x11010000,
  0x0AC10000, 0x09C10000, 0x08A10000, 0x05210000, 0x04410000, 0x02A10000,
  0x02210000, 0x01410000, 0x01110000, 0x00850000, 0x00490000, 0x00250000,
  0x00150000, 0x00090000, 0x00050000, 0x00010000, 0x56010000
]

# Next state table for MPS (47 entries)
const nmpsTable = [
  1, 2, 3, 4, 5, 38, 7, 8, 9, 10, 11, 12, 13, 29, 15, 16, 17, 18, 19, 20,
  21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
  39, 40, 41, 42, 43, 44, 45, 45, 46
]

# Next state table for LPS (47 entries)
const nlpsTable = [
  1, 6, 9, 12, 29, 33, 6, 14, 14, 14, 17, 18, 20, 21, 14, 14, 15, 16, 17, 18,
  19, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
  36, 37, 38, 39, 40, 41, 42, 43, 46
]

# Switch table - 1 means invert MPS on LPS (47 entries)
const switchTable = [
  1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0
]

proc newArithmeticDecoderStats*(contextSize: int = 4096): ArithmeticDecoderStats =
  ## Create new arithmetic decoder statistics
  result = ArithmeticDecoderStats(
    contextSize: contextSize,
    codingContextTable: newSeq[int](contextSize),
    contextTable: newSeq[int](contextSize)
  )
  for i in 0..<contextSize:
    result.codingContextTable[i] = 0
    result.contextTable[i] = 0

proc reset*(stats: ArithmeticDecoderStats) =
  ## Reset statistics
  for i in 0..<stats.contextSize:
    stats.codingContextTable[i] = 0

proc reset*(decoder: ArithmeticDecoder) =
  ## Reset arithmetic decoder state
  decoder.a = 0x10000
  decoder.c = 0
  decoder.buffer0 = 0
  decoder.buffer1 = 0
  decoder.previous = 0
  decoder.counter = 0
  decoder.currentBit = 0
  decoder.currentByte = 0

proc getContextCodingTableValue*(stats: ArithmeticDecoderStats, index: int): int =
  ## Get context coding table value
  result = stats.codingContextTable[index]

proc setContextCodingTableValue*(stats: ArithmeticDecoderStats, index: int, value: int) =
  ## Set context coding table value
  stats.codingContextTable[index] = value

proc getContextSize*(stats: ArithmeticDecoderStats): int =
  ## Get context size
  result = stats.contextSize

proc overwrite*(stats: ArithmeticDecoderStats, other: ArithmeticDecoderStats) =
  ## Copy statistics from another stats object
  for i in 0..<min(stats.contextSize, other.contextSize):
    stats.codingContextTable[i] = other.codingContextTable[i]

proc copy*(stats: ArithmeticDecoderStats): ArithmeticDecoderStats =
  ## Create a copy of statistics
  result = newArithmeticDecoderStats(stats.contextSize)
  for i in 0..<stats.contextSize:
    result.codingContextTable[i] = stats.codingContextTable[i]

proc bit32ShiftL*(value: int64, shift: int): int64 =
  ## 32-bit left shift
  result = (value shl shift) and 0xFFFFFFFF'i64

proc bit32ShiftR*(value: int64, shift: int): int64 =
  ## 32-bit right shift
  result = (value shr shift) and 0xFFFFFFFF'i64

proc newArithmeticDecoder*(reader: Big2StreamReader): ArithmeticDecoder =
  ## Create new arithmetic decoder
  result = ArithmeticDecoder(
    reader: reader,
    genericRegionStats: newArithmeticDecoderStats(1 shl 1),
    refinementRegionStats: newArithmeticDecoderStats(1 shl 1),
    iadhStats: newArithmeticDecoderStats(1 shl 9),
    iadwStats: newArithmeticDecoderStats(1 shl 9),
    iaexStats: newArithmeticDecoderStats(1 shl 9),
    iaaiStats: newArithmeticDecoderStats(1 shl 9),
    iadtStats: newArithmeticDecoderStats(1 shl 9),
    iaitStats: newArithmeticDecoderStats(1 shl 9),
    iafsStats: newArithmeticDecoderStats(1 shl 9),
    iadsStats: newArithmeticDecoderStats(1 shl 9),
    iardxStats: newArithmeticDecoderStats(1 shl 9),
    iardyStats: newArithmeticDecoderStats(1 shl 9),
    iardwStats: newArithmeticDecoderStats(1 shl 9),
    iardhStats: newArithmeticDecoderStats(1 shl 9),
    iariStats: newArithmeticDecoderStats(1 shl 9),
    iaidStats: newArithmeticDecoderStats(1 shl 9),
    buffer0: 0,
    buffer1: 0,
    c: 0,
    a: 0x10000,
    previous: 0,
    counter: 0,
    currentBit: 0,
    currentByte: 0
  )

proc readByteInternal(decoder: ArithmeticDecoder) =
  ## Internal byte reading with byte stuffing handling (equivalent to C# readbyte)
  if decoder.buffer0 == 0xFF:
    if decoder.buffer1 > 0x8F:
      decoder.counter = 8
    else:
      decoder.buffer0 = decoder.buffer1
      decoder.buffer1 = decoder.reader.readByte().int64
      decoder.c = decoder.c + 0xFE00 - bit32ShiftL(decoder.buffer0, 9)
      decoder.counter = 7
  else:
    decoder.buffer0 = decoder.buffer1
    decoder.buffer1 = decoder.reader.readByte().int64
    decoder.c = decoder.c + 0xFF00 - bit32ShiftL(decoder.buffer0, 8)
    decoder.counter = 8

proc start*(decoder: ArithmeticDecoder) =
  ## Initialize/reset the arithmetic decoder - exactly matching C# start()
  decoder.buffer0 = decoder.reader.readByte().int64
  decoder.buffer1 = decoder.reader.readByte().int64
  decoder.c = bit32ShiftL((decoder.buffer0 xor 0xFF), 16)
  readByteInternal(decoder)
  decoder.c = bit32ShiftL(decoder.c, 7)
  decoder.counter -= 7
  decoder.a = 0x80000000'i64

proc resetIntStats*(decoder: ArithmeticDecoder, symbolCodeLength: int) =
  ## Reset integer statistics
  decoder.iadhStats.reset()
  decoder.iadwStats.reset()
  decoder.iaexStats.reset()
  decoder.iaaiStats.reset()
  decoder.iadtStats.reset()
  decoder.iaitStats.reset()
  decoder.iafsStats.reset()
  decoder.iadsStats.reset()
  decoder.iardxStats.reset()
  decoder.iardyStats.reset()
  decoder.iardwStats.reset()
  decoder.iardhStats.reset()
  decoder.iariStats.reset()
  
  if decoder.iaidStats.getContextSize() == (1 shl (symbolCodeLength + 1)):
    decoder.iaidStats.reset()
  else:
    decoder.iaidStats = newArithmeticDecoderStats(1 shl (symbolCodeLength + 1))

proc resetGenericStats*(decoder: ArithmeticDecoder, tmpl: int, previousStats: ArithmeticDecoderStats) =
  ## Reset generic region statistics
  ## Uses contextSize array (not referredToContextSize) for generic region decoding
  let size = contextSize[tmpl]
  let statsSize = 1 shl size  # Stats array size is 2^size
  
  if previousStats != nil and previousStats.getContextSize() == statsSize:
    if decoder.genericRegionStats.getContextSize() == statsSize:
      decoder.genericRegionStats.overwrite(previousStats)
    else:
      decoder.genericRegionStats = previousStats.copy()
  else:
    if decoder.genericRegionStats.getContextSize() == statsSize:
      decoder.genericRegionStats.reset()
    else:
      decoder.genericRegionStats = newArithmeticDecoderStats(statsSize)

proc resetRefinementStats*(decoder: ArithmeticDecoder, tmpl: int, previousStats: ArithmeticDecoderStats) =
  ## Reset refinement region statistics
  let size = referredToContextSize[tmpl]
  let statsSize = 1 shl size  # Stats array size is 2^size
  
  if previousStats != nil and previousStats.getContextSize() == statsSize:
    if decoder.refinementRegionStats.getContextSize() == statsSize:
      decoder.refinementRegionStats.overwrite(previousStats)
    else:
      decoder.refinementRegionStats = previousStats.copy()
  else:
    if decoder.refinementRegionStats.getContextSize() == statsSize:
      decoder.refinementRegionStats.reset()
    else:
      decoder.refinementRegionStats = newArithmeticDecoderStats(statsSize)

proc decodeBit*(decoder: ArithmeticDecoder, context: int64, stats: ArithmeticDecoderStats): int =
  ## Decode a single bit using arithmetic coding - exactly matching C# decodeBit()
  # C#: int iCX = BinaryOperation.bit8Shift(stats.getContextCodingTableValue((int) context), 1, BinaryOperation.RIGHT_SHIFT);
  # bit8Shift with RIGHT_SHIFT: number >>= shift; return (number & INTMASK) where INTMASK = 0xFF
  let contextValue = stats.getContextCodingTableValue(context.int)
  let iCX = (contextValue shr 1) and 0xFF
  let mpsCX = contextValue and 1
  let qe = qeTable[iCX]
  
  decoder.a -= qe
  
  var bit: int
  if decoder.c < decoder.a:
    if (decoder.a and 0x80000000'i64) != 0:
      bit = mpsCX
    else:
      if decoder.a < qe:
        bit = 1 - mpsCX
        if switchTable[iCX] != 0:
          stats.setContextCodingTableValue(context.int, (nlpsTable[iCX] shl 1) or (1 - mpsCX))
        else:
          stats.setContextCodingTableValue(context.int, (nlpsTable[iCX] shl 1) or mpsCX)
      else:
        bit = mpsCX
        stats.setContextCodingTableValue(context.int, (nmpsTable[iCX] shl 1) or mpsCX)
      
      while true:
        if decoder.counter == 0:
          readByteInternal(decoder)
        decoder.a = bit32ShiftL(decoder.a, 1)
        decoder.c = bit32ShiftL(decoder.c, 1)
        decoder.counter -= 1
        if (decoder.a and 0x80000000'i64) != 0:
          break
  else:
    decoder.c -= decoder.a
    if decoder.a < qe:
      bit = mpsCX
      stats.setContextCodingTableValue(context.int, (nmpsTable[iCX] shl 1) or mpsCX)
    else:
      bit = 1 - mpsCX
      if switchTable[iCX] != 0:
        stats.setContextCodingTableValue(context.int, (nlpsTable[iCX] shl 1) or (1 - mpsCX))
      else:
        stats.setContextCodingTableValue(context.int, (nlpsTable[iCX] shl 1) or mpsCX)
    decoder.a = qe
    
    while true:
      if decoder.counter == 0:
        readByteInternal(decoder)
      decoder.a = bit32ShiftL(decoder.a, 1)
      decoder.c = bit32ShiftL(decoder.c, 1)
      decoder.counter -= 1
      if (decoder.a and 0x80000000'i64) != 0:
        break
  
  result = bit

proc decodeIntBit*(decoder: ArithmeticDecoder, stats: ArithmeticDecoderStats): int64 =
  ## Decode a single bit for integer decoding - exactly matching C#
  let bit = decoder.decodeBit(decoder.previous, stats)
  # C#: previous = (BinaryOperation.bit32ShiftL(previous, 1) | bit) & 0x1ff;
  # or: previous = ((BinaryOperation.bit32ShiftL(previous, 1) | bit) & 0x1ff) | 0x100;
  # Note: C# bit32ShiftL doesn't mask, it just shifts
  if decoder.previous < 0x100:
    decoder.previous = ((decoder.previous shl 1) or bit) and 0x1FF
  else:
    decoder.previous = (((decoder.previous shl 1) or bit) and 0x1FF) or 0x100
  result = bit

proc decodeInt*(decoder: ArithmeticDecoder, stats: ArithmeticDecoderStats): DecodeIntResult =
  ## Decode an integer using arithmetic coding - exactly matching C# decodeInt()
  var value: int64

  decoder.previous = 1
  let s = decoder.decodeIntBit(stats)
  
  if decoder.decodeIntBit(stats) != 0:
    if decoder.decodeIntBit(stats) != 0:
      if decoder.decodeIntBit(stats) != 0:
        if decoder.decodeIntBit(stats) != 0:
          if decoder.decodeIntBit(stats) != 0:
            value = 0
            for i in 0..<32:
              value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
            value += 4436
          else:
            value = 0
            for i in 0..<12:
              value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
            value += 340
        else:
          value = 0
          for i in 0..<8:
            value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
          value += 84
      else:
        value = 0
        for i in 0..<6:
          value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
        value += 20
    else:
      value = decoder.decodeIntBit(stats)
      value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
      value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
      value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)
      value += 4
  else:
    value = decoder.decodeIntBit(stats)
    value = bit32ShiftL(value, 1) or decoder.decodeIntBit(stats)

  var decodedInt: int
  if s != 0:
    if value == 0:
      return DecodeIntResult(value: 0, success: false)
    decodedInt = -value.int
  else:
    decodedInt = value.int

  result = DecodeIntResult(value: decodedInt, success: true)

proc decodeIAID*(decoder: ArithmeticDecoder, codeLen: int64, stats: ArithmeticDecoderStats): int64 =
  ## Decode IAID (Integer Arithmetic ID) - exactly matching C#
  decoder.previous = 1
  for i in 0..<codeLen:
    let bit = decoder.decodeBit(decoder.previous, stats)
    decoder.previous = bit32ShiftL(decoder.previous, 1) or bit

  result = decoder.previous - (1'i64 shl codeLen.int)

# Compatibility methods
proc readBit*(decoder: ArithmeticDecoder, context: int): int =
  ## Read a single bit (compatibility method)
  result = decoder.reader.readBit()

proc readBits*(decoder: ArithmeticDecoder, bits: int, context: int = 0): int =
  ## Read multiple bits (compatibility method)
  result = decoder.reader.readBits(bits).int

# -----------------------------------------------------------------------------
# ArithmeticIntegerDecoder - wraps ArithmeticDecoder for integer decoding
# Equivalent to Java's org.apache.pdfbox.jbig2.decoder.arithmetic.ArithmeticIntegerDecoder
# -----------------------------------------------------------------------------

type
  ArithmeticIntegerDecoder* = ref object
    decoder*: ArithmeticDecoder

proc newArithmeticIntegerDecoder*(decoder: ArithmeticDecoder): ArithmeticIntegerDecoder =
  ## Create new ArithmeticIntegerDecoder wrapping an ArithmeticDecoder
  ## Equivalent to: ArithmeticIntegerDecoder aid = new ArithmeticIntegerDecoder(ad)
  result = ArithmeticIntegerDecoder(decoder: decoder)

proc decode*(aid: ArithmeticIntegerDecoder, stats: ArithmeticDecoderStats = nil): int64 =
  ## Decode an integer using arithmetic coding
  ## Equivalent to Java's: long result = aid.decode(null)
  ## 
  ## Parameters:
  ##   stats - Statistics for decoding (can be nil/null)
  ## Returns:
  ##   The decoded integer value
  
  # Use default stats if nil is passed (equivalent to decode(null) in Java)
  let actualStats = if stats == nil: newArithmeticDecoderStats() else: stats
  
  # C#: decoder.previous = 1;
  aid.decoder.previous = 1
  
  let s = aid.decoder.decodeIntBit(actualStats)
  
  var value: int64
  
  if aid.decoder.decodeIntBit(actualStats) != 0:
    if aid.decoder.decodeIntBit(actualStats) != 0:
      if aid.decoder.decodeIntBit(actualStats) != 0:
        if aid.decoder.decodeIntBit(actualStats) != 0:
          if aid.decoder.decodeIntBit(actualStats) != 0:
            value = 0
            for i in 0..<32:
              value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
            value += 4436
          else:
            value = 0
            for i in 0..<12:
              value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
            value += 340
        else:
          value = 0
          for i in 0..<8:
            value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
          value += 84
      else:
        value = 0
        for i in 0..<6:
          value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
        value += 20
    else:
      value = aid.decoder.decodeIntBit(actualStats)
      value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
      value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
      value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
      value += 4
  else:
    value = aid.decoder.decodeIntBit(actualStats)
    value = bit32ShiftL(value, 1) or aid.decoder.decodeIntBit(actualStats)
  
  if s != 0:
    if value == 0:
      return 0
    result = -value
  else:
    result = value
