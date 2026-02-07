## Sample JBIG2 test file - Single page document
## This file contains a minimal JBIG2 single page document for testing

import jbig2_decoder

# JBIG2 header (8 bytes)
proc createSinglePageJBIG2*(): seq[byte] =
  result = @[
    0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8,  # Magic bytes "JB2\n"
    0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,  # Version and flags
  ]
  
  # File header flags (1 byte) - sequential organization, pages known
  result.add(0x00'u8)
  
  # Number of pages (4 bytes) - 1 page
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  
  # Page Information Segment
  # Segment number (4 bytes)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  
  # Segment header flags (1 byte) - Page Information
  result.add(PAGE_INFORMATION.byte)
  
  # Referred-to segment count and retention flags (1 byte)
  result.add(0x00'u8)
  
  # Page association (1 byte) - page 1
  result.add(0x01'u8)
  
  # Segment data length (4 bytes) - 20 bytes
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x14'u8)
  
  # Page Information Data (20 bytes)
  # Width (4 bytes) - 200 pixels
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0xC8'u8)
  
  # Height (4 bytes) - 300 pixels
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  result.add(0x2C'u8)
  
  # Resolution X (4 bytes) - 72 DPI
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)
  
  # Resolution Y (4 bytes) - 72 DPI
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)
  
  # Flags (4 bytes)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  
  # End of File Segment
  # Segment number (4 bytes)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x02'u8)
  
  # Segment header flags (1 byte) - End of File
  result.add(END_OF_FILE.byte)
  
  # Referred-to segment count and retention flags (1 byte)
  result.add(0x00'u8)
  
  # Page association (1 byte) - page 1
  result.add(0x01'u8)
  
  # Segment data length (4 bytes) - 0 bytes
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)

proc createMultiPageJBIG2*(): seq[byte] =
  ## Create a multi-page JBIG2 document
  result = @[
    0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8,  # Magic bytes "JB2\n"
    0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,  # Version and flags
  ]
  
  # File header flags (1 byte) - sequential organization, pages known
  result.add(0x00'u8)
  
  # Number of pages (4 bytes) - 3 pages
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x03'u8)
  
  # Page 1 Information Segment
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)  # Segment number 1
  result.add(PAGE_INFORMATION.byte)
  result.add(0x00'u8)  # Flags
  result.add(0x01'u8)  # Page association 1
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x14'u8)  # Data length 20
  
  # Page 1 data (same as single page)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0xC8'u8)  # Width 200
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  result.add(0x2C'u8)  # Height 300
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # X resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # Y resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  
  # Page 2 Information Segment
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x02'u8)  # Segment number 2
  result.add(PAGE_INFORMATION.byte)
  result.add(0x00'u8)  # Flags
  result.add(0x02'u8)  # Page association 2
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x14'u8)  # Data length 20
  
  # Page 2 data (same dimensions)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0xC8'u8)  # Width 200
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  result.add(0x2C'u8)  # Height 300
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # X resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # Y resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  
  # Page 3 Information Segment
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x03'u8)  # Segment number 3
  result.add(PAGE_INFORMATION.byte)
  result.add(0x00'u8)  # Flags
  result.add(0x03'u8)  # Page association 3
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x14'u8)  # Data length 20
  
  # Page 3 data (same dimensions)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0xC8'u8)  # Width 200
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x01'u8)
  result.add(0x2C'u8)  # Height 300
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # X resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x48'u8)  # Y resolution 72
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  
  # End of File Segment
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x04'u8)  # Segment number 4
  result.add(END_OF_FILE.byte)
  result.add(0x00'u8)  # Flags
  result.add(0x01'u8)  # Page association 1
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)
  result.add(0x00'u8)  # Data length 0

proc createCorruptedJBIG2*(): seq[byte] =
  ## Create a corrupted JBIG2 document for error handling tests
  result = @[
    0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8,  # Invalid header
    0xFF'u8, 0xFF'u8, 0xFF'u8, 0xFF'u8,
    0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,  # Invalid data
    0x00'u8, 0x00'u8, 0x00'u8, 0x00'u8,
  ]

proc createArithmeticTestData*(): seq[byte] =
  ## Create test data for arithmetic decoder testing
  result = @[
    0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8,  # Magic bytes
    0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,
    0x00'u8,  # Flags
    0x00'u8, 0x00'u8, 0x00'u8, 0x01'u8,  # 1 page
    # Test sequence for arithmetic coding
    0x55'u8, 0xAA'u8, 0x55'u8, 0xAA'u8,  # Alternating pattern
    0xFF'u8, 0x00'u8, 0xFF'u8, 0x00'u8,  # High contrast pattern
    0x0F'u8, 0xF0'u8, 0x0F'u8, 0xF0'u8,  # Nibble pattern
  ]

proc createMMRTestData*(): seq[byte] =
  ## Create test data for MMR decoder testing
  result = @[
    0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8,  # Magic bytes
    0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,
    0x00'u8,  # Flags
    0x00'u8, 0x00'u8, 0x00'u8, 0x01'u8,  # 1 page
    # Test sequence for MMR coding
    0xFF'u8, 0x00'u8, 0xFF'u8, 0x00'u8,  # Run-length pattern
    0xAA'u8, 0x55'u8, 0xAA'u8, 0x55'u8,  # Alternating runs
    0xF0'u8, 0x0F'u8, 0xF0'u8, 0x0F'u8,  # Half-byte runs
  ]

proc createHuffmanTestData*(): seq[byte] =
  ## Create test data for Huffman decoder testing
  result = @[
    0x97'u8, 0x4A'u8, 0x42'u8, 0x32'u8,  # Magic bytes
    0x0D'u8, 0x0A'u8, 0x1A'u8, 0x0A'u8,
    0x00'u8,  # Flags
    0x00'u8, 0x00'u8, 0x00'u8, 0x01'u8,  # 1 page
    # Test sequence for Huffman coding
    0x00'u8, 0x01'u8, 0x02'u8, 0x03'u8,  # Sequential values
    0x04'u8, 0x05'u8, 0x06'u8, 0x07'u8,
    0x08'u8, 0x09'u8, 0x0A'u8, 0x0B'u8,
  ]