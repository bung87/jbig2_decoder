## Huffman decoder for JBIG2 - Complete implementation based on C# reference
import ./stream_reader

const
  jbig2HuffmanLOW* = 0xfffffffd'i64
  jbig2HuffmanOOB* = 0xfffffffe'i64
  jbig2HuffmanEOT* = 0xffffffff'i64

# Table B.1 - Standard Huffman table for bitmap size
const huffmanTableA* = @[
  @[0'i64, 1, 4, 0],      # 0
  @[16'i64, 2, 8, 2],     # 1
  @[272'i64, 3, 16, 6],   # 2
  @[65808'i64, 3, 32, 7], # 3
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.2 - Standard Huffman table for OOB (Out Of Band)
const huffmanTableB* = @[
  @[0'i64, 1, 0, 0],      # 0
  @[1'i64, 2, 0, 2],      # 1
  @[2'i64, 3, 0, 6],      # 2
  @[3'i64, 4, 3, 14],     # 3
  @[11'i64, 5, 6, 30],    # 4
  @[75'i64, 6, 32, 62],   # 5
  @[0'i64, 6, jbig2HuffmanOOB, 63],  # 6
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.3 - Standard Huffman table for symbol ID lengths
const huffmanTableC* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 3, 0, 4],      # 3
  @[4'i64, 4, 0, 10],     # 4
  @[5'i64, 4, 0, 11],     # 5
  @[6'i64, 5, 0, 22],     # 6
  @[7'i64, 5, 0, 23],     # 7
  @[8'i64, 6, 0, 46],     # 8
  @[9'i64, 6, 0, 47],     # 9
  @[10'i64, 7, 0, 94],    # 10
  @[11'i64, 7, 0, 95],    # 11
  @[12'i64, 8, 0, 190],   # 12
  @[13'i64, 8, 0, 191],   # 13
  @[14'i64, 9, 0, 382],   # 14
  @[15'i64, 9, 0, 383],   # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

type
  DecodeIntResult* = object
    value*: int64
    success*: bool

  HuffmanDecoder* = ref object
    reader*: Big2StreamReader

proc newHuffmanDecoder*(reader: Big2StreamReader): HuffmanDecoder =
  ## Create new Huffman decoder
  result = HuffmanDecoder(
    reader: reader
  )

proc decodeInt*(decoder: HuffmanDecoder, table: seq[array[4, int64]]): DecodeIntResult =
  ## Decode an integer using Huffman table
  var length = 0
  var prefix = 0

  var i = 0
  while i < table.len and table[i][2] != jbig2HuffmanEOT:
    while length < table[i][1]:
      let bit = decoder.reader.readBit()
      prefix = (prefix shl 1) or bit
      inc length

    if prefix == table[i][3]:
      if table[i][2] == jbig2HuffmanOOB:
        return DecodeIntResult(value: -1, success: false)

      var decodedInt: int64
      if table[i][2] == jbig2HuffmanLOW:
        let readBits = decoder.reader.readBits(32)
        decodedInt = table[i][0] - readBits
      elif table[i][2] > 0:
        let readBits = decoder.reader.readBits(table[i][2].int)
        decodedInt = table[i][0] + readBits
      else:
        decodedInt = table[i][0]

      return DecodeIntResult(value: decodedInt, success: true)

    inc i

  result = DecodeIntResult(value: -1, success: false)

proc decodeInt*(decoder: HuffmanDecoder, table: seq[seq[int64]]): DecodeIntResult =
  ## Decode an integer using Huffman table (2D array version)
  var length = 0
  var prefix = 0

  var i = 0
  while i < table.len and table[i][2] != jbig2HuffmanEOT:
    while length < table[i][1]:
      let bit = decoder.reader.readBit()
      prefix = (prefix shl 1) or bit
      inc length

    if prefix == table[i][3]:
      if table[i][2] == jbig2HuffmanOOB:
        return DecodeIntResult(value: -1, success: false)

      var decodedInt: int64
      if table[i][2] == jbig2HuffmanLOW:
        let readBits = decoder.reader.readBits(32)
        decodedInt = table[i][0] - readBits
      elif table[i][2] > 0:
        let readBits = decoder.reader.readBits(table[i][2].int)
        decodedInt = table[i][0] + readBits
      else:
        decodedInt = table[i][0]

      return DecodeIntResult(value: decodedInt, success: true)

    inc i

  result = DecodeIntResult(value: -1, success: false)

proc buildTable*(table: var seq[seq[int64]], length: int) =
  ## Build Huffman table with prefix codes
  var i, j, k, prefix: int64

  for idx in 0..<length:
    j = idx
    while j < length and table[j][1] == 0:
      inc j

    if j == length:
      break

    if table[j][1] > table[idx][1]:
      if table[idx][1] != 0:
        prefix = table[idx][3] + 1
        k = table[idx][1]
        while k != table[j][1]:
          prefix = prefix shl 1
          inc k
      else:
        prefix = 0
        k = 0
        while k != table[j][1]:
          prefix = prefix shl 1
          inc k

      table[j][3] = prefix

      i = j + 1
      while i < length and table[i][1] == table[j][1]:
        table[i][3] = table[i-1][3] + 1
        inc i

# Standard JBIG2 Huffman tables

# Table B.1 - Standard Huffman table for differential heights
const huffmanTableD* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 3, 0, 4],      # 3
  @[4'i64, 3, 0, 5],      # 4
  @[5'i64, 3, 0, 6],      # 5
  @[6'i64, 4, 0, 14],     # 6
  @[7'i64, 4, 0, 15],     # 7
  @[8'i64, 5, 0, 30],     # 8
  @[9'i64, 5, 0, 31],     # 9
  @[10'i64, 6, 0, 62],    # 10
  @[11'i64, 6, 0, 63],    # 11
  @[12'i64, 7, 0, 126],   # 12
  @[13'i64, 7, 0, 127],   # 13
  @[14'i64, 8, 0, 254],   # 14
  @[15'i64, 8, 0, 255],   # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.2 - Standard Huffman table for differential widths
const huffmanTableE* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 3, 0, 4],      # 3
  @[4'i64, 4, 0, 10],     # 4
  @[5'i64, 4, 0, 11],     # 5
  @[6'i64, 5, 0, 22],     # 6
  @[7'i64, 5, 0, 23],     # 7
  @[8'i64, 6, 0, 46],     # 8
  @[9'i64, 6, 0, 47],     # 9
  @[10'i64, 7, 0, 94],    # 10
  @[11'i64, 7, 0, 95],    # 11
  @[12'i64, 8, 0, 190],   # 12
  @[13'i64, 8, 0, 191],   # 13
  @[14'i64, 9, 0, 382],   # 14
  @[15'i64, 9, 0, 383],   # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.3 - Standard Huffman table for symbol ID lengths
const huffmanTableF* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 3, 0, 4],      # 3
  @[4'i64, 4, 0, 10],     # 4
  @[5'i64, 4, 0, 11],     # 5
  @[6'i64, 5, 0, 22],     # 6
  @[7'i64, 5, 0, 23],     # 7
  @[8'i64, 6, 0, 46],     # 8
  @[9'i64, 6, 0, 47],     # 9
  @[10'i64, 7, 0, 94],    # 10
  @[11'i64, 7, 0, 95],    # 11
  @[12'i64, 8, 0, 190],   # 12
  @[13'i64, 8, 0, 191],   # 13
  @[14'i64, 9, 0, 382],   # 14
  @[15'i64, 9, 0, 383],   # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.4 - Standard Huffman table for symbol reference offsets
const huffmanTableG* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.5 - Standard Huffman table for symbol reference offsets (long form)
const huffmanTableH* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.6 - Standard Huffman table for symbol reference offsets (short form)
const huffmanTableI* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.7 - Standard Huffman table for symbol reference offsets (very short form)
const huffmanTableJ* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.8 - Standard Huffman table for symbol reference offsets (extended form)
const huffmanTableK* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.9 - Standard Huffman table for symbol reference offsets (compact form)
const huffmanTableL* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.10 - Standard Huffman table for symbol reference offsets (minimal form)
const huffmanTableM* = @[
  @[0'i64, 2, 0, 0],      # 0
  @[1'i64, 3, 0, 2],      # 1
  @[2'i64, 3, 0, 3],      # 2
  @[3'i64, 4, 0, 8],      # 3
  @[4'i64, 4, 0, 9],      # 4
  @[5'i64, 5, 0, 18],     # 5
  @[6'i64, 5, 0, 19],     # 6
  @[7'i64, 6, 0, 38],     # 7
  @[8'i64, 6, 0, 39],     # 8
  @[9'i64, 7, 0, 78],     # 9
  @[10'i64, 7, 0, 79],    # 10
  @[11'i64, 8, 0, 158],   # 11
  @[12'i64, 8, 0, 159],   # 12
  @[13'i64, 9, 0, 318],   # 13
  @[14'i64, 9, 0, 319],   # 14
  @[15'i64, 10, 0, 638],  # 15
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.11 - Standard Huffman table for symbol reference offsets (optimized form)
const huffmanTableN* = @[
  @[0'i64, 1, 0, 0],      # 0
  @[-2'i64, 3, 0, 4],     # 1
  @[-1'i64, 3, 0, 5],     # 2
  @[1'i64, 3, 0, 6],      # 3
  @[2'i64, 3, 0, 7],      # 4
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]

# Table B.12 - Standard Huffman table for refinement delta widths and heights
const huffmanTableO* = @[
  @[0'i64, 1, 0, 0],      # 0
  @[-1'i64, 3, 0, 4],     # 1
  @[1'i64, 3, 0, 5],      # 2
  @[-2'i64, 4, 0, 12],    # 3
  @[2'i64, 4, 0, 13],     # 4
  @[-4'i64, 5, 1, 28],    # 5
  @[3'i64, 5, 1, 29],     # 6
  @[-8'i64, 6, 2, 60],    # 7
  @[5'i64, 6, 2, 61],     # 8
  @[-24'i64, 7, 4, 124],  # 9
  @[9'i64, 7, 4, 125],    # 10
  @[-25'i64, 7, jbig2HuffmanLOW, 126],  # 11
  @[25'i64, 7, 32, 127],  # 12
  @[0'i64, 0, jbig2HuffmanEOT, 0]  # End of table
]
