# JBig2Decoder for Nim ![Test Status](https://github.com/bung87/jbig2_decoder/workflows/test/badge.svg)

A Nim library for decoding JBIG2 (Joint Bi-level Image experts Group) compressed images, commonly used in PDF documents and fax transmissions.

## Features

- **JBIG2 Format Support**: Decode JBIG2 compressed images
- **Multiple Compression Types**: Supports arithmetic coding, Huffman coding, and MMR compression
- **Segment-based Architecture**: Handles all JBIG2 segment types (text regions, generic regions, halftone regions, etc.)
- **Multi-page Support**: Can handle multi-page JBIG2 documents
- **Pure Nim Implementation**: No external dependencies required

## Installation

```bash
nimble install jbig2_decoder
```

## Quick Start

```nim
import jbig2_decoder

# Simple decoding
let imageData = readFile("input.jbig2")
let decoder = newJBIG2StreamDecoder()
let decodedData = decoder.decodeJBIG2(imageData, TIFF)
writeFile("output.tiff", decodedData)

# Advanced usage with decoder instance
let decoder = newJBIG2StreamDecoder()
let result = decoder.decodeJBIG2(imageData)
echo "Number of pages: ", decoder.noOfPages
echo "Segments found: ", decoder.segments.len
```

## API Reference

### Main Functions

#### `decodeJBIG2(decoder: JBIG2StreamDecoder, data: seq[byte], format: ImageFormat = TIFF, newWidth: int = 0, newHeight: int = 0): seq[byte]`
Decode JBIG2 compressed image data.

**Parameters:**
- `decoder`: The JBIG2 stream decoder instance
- `data`: The JBIG2 compressed image data
- `format`: Output format (JPEG or TIFF)
- `newWidth`: Optional width for resizing (0 means no resize)
- `newHeight`: Optional height for resizing (0 means no resize)

**Returns:** Decoded image data in the specified format

#### `newJBIG2StreamDecoder(): JBIG2StreamDecoder`
Create a new JBIG2 stream decoder instance.

### Decoder Properties

The `JBIG2StreamDecoder` type exposes the following public fields:

- `noOfPages`: int - The number of pages in the JBIG2 file (-1 if unknown)
- `noOfPagesKnown`: bool - Whether the number of pages is known
- `randomAccessOrganisation`: bool - Whether random access organization is used
- `segments`: seq[Segment] - All segments found in the file
- `bitmaps`: seq[JBIG2Bitmap] - Decoded bitmaps
- `debug`: bool - Enable/disable debug output

### Bitmap Operations

#### `newJBIG2Bitmap(width, height, bitmapNumber: int): JBIG2Bitmap`
Create a new JBIG2 bitmap with specified dimensions.

#### `getPixel(bitmap: JBIG2Bitmap, x, y: int): int`
Get pixel value at (x, y).

#### `setPixel(bitmap: JBIG2Bitmap, x, y: int, value: int)`
Set pixel value at (x, y).

#### `getData(bitmap: JBIG2Bitmap, switchPixelColor: bool = false): seq[byte]`
Get bitmap data as a flat byte sequence.

#### `width`: int - Bitmap width (public field)
#### `height`: int - Bitmap height (public field)

## Examples

### Basic Image Decoding

```nim
import jbig2_decoder

# Read JBIG2 file
let imageData = readFile("document.jbig2")

# Decode using decoder instance
let decoder = newJBIG2StreamDecoder()
let tiffData = decoder.decodeJBIG2(imageData, TIFF)
writeFile("document.tiff", tiffData)
```

### Working with Multi-page Documents

```nim
import jbig2_decoder

let decoder = newJBIG2StreamDecoder()
let imageData = readFile("multipage.jbig2")

discard decoder.decodeJBIG2(imageData)

echo "Pages: ", decoder.noOfPages

# Access decoded bitmaps
for i, bitmap in decoder.bitmaps:
  echo fmt"Bitmap {i}: {bitmap.width}x{bitmap.height}"
```

### Advanced Segment Analysis

```nim
import jbig2_decoder

let decoder = newJBIG2StreamDecoder()
decoder.debug = true

let imageData = readFile("complex.jbig2")
discard decoder.decodeJBIG2(imageData)

echo "Found ", decoder.segments.len, " segments"

for segment in decoder.segments:
  let header = segment.getSegmentHeader()
  echo "Segment ", header.segmentNumber, ": type ", header.segmentType
```

## Architecture

The library is organized into several key components:

- **Stream Reader**: Handles low-level bit and byte reading from JBIG2 streams
- **Binary Operations**: Utility functions for bit manipulation and data conversion
- **Segment System**: Handles different types of JBIG2 segments (regions, dictionaries, etc.)
- **Decoders**: Implement different compression algorithms (Arithmetic, Huffman, MMR)
- **Bitmap System**: Manages the decoded image data
- **Main Decoder**: Orchestrates the entire decoding process

## Supported JBIG2 Features

- **Segment Types**: All major JBIG2 segment types are supported
  - Symbol Dictionary (0)
  - Text Region (4-6)
  - Pattern Dictionary (16)
  - Halftone Region (20-22)
  - Generic Region (36-38)
  - Generic Refinement Region (39-41)
  - Page Information (48)
  - End of File (51)
- **Compression Methods**: Arithmetic coding, Huffman coding, MMR
- **Region Types**: Generic, text, halftone, and refinement regions
- **Dictionaries**: Symbol and pattern dictionaries
- **File Organizations**: Both sequential and random access
- **Multi-page Support**: Full support for multi-page documents

## Error Handling

The library defines custom exception types:

- `JBig2Error`: Base exception for JBIG2 decoder errors
- `InvalidHeaderValueError`: Invalid header value encountered
- `IntegerMaxValueError`: Integer value exceeds maximum allowed

## Contributing

Contributions are welcome! Areas that could use improvement:

- Implementing remaining segment types
- Optimizing decoder performance
- Adding more comprehensive tests
- Improving error handling
- Adding more output format support

## License

MIT License - See LICENSE file for details.

## References

- JBIG2 Specification (ISO/IEC 14492)
- JBIG2 Decoder C# implementation (original source)
- JBIG2 Wikipedia article
