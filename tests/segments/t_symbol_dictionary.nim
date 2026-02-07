## Symbol Dictionary Segment tests
import std/[os, strformat]
import jbig2_decoder/jbig2_bitmap

block SymbolDictionaryTests:
  # Test basic symbol dictionary creation
  block BasicSymbolDictionary:
    # Create a symbol dictionary with several symbols
    let dictionarySize = 4
    var symbols: seq[JBIG2Bitmap] = @[]
    
    # Create symbols with different patterns
    for i in 0..<dictionarySize:
      let symbol = newJBIG2Bitmap(16, 16, i)
      
      # Create unique symbol pattern
      for x in 0..<symbol.width:
        for y in 0..<symbol.height:
          let pixelValue = if (x * y + i) mod 2 == 0: 1 else: 0
          symbol.setPixel(x, y, pixelValue)
      
      symbols.add(symbol)
    
    # Verify all symbols are stored
    doAssert symbols.len == dictionarySize, "Symbol dictionary should contain exactly " & $dictionarySize & " symbols"
    
    # Verify each symbol has unique bitmap number
    for i in 0..<dictionarySize:
      doAssert symbols[i].bitmapNumber == i, fmt"Symbol {i} should have bitmap number {i}"

  # Test symbol dictionary with different sizes
  block SymbolDictionarySizes:
    # Test different symbol sizes
    let sizes = [(8, 8), (12, 12), (16, 16), (20, 20)]
    
    for (width, height) in sizes:
      let symbol = newJBIG2Bitmap(width, height, 0)
      
      # Fill with a simple pattern
      for x in 0..<width:
        for y in 0..<height:
          let pixelValue = if (x + y) mod 3 == 0: 1 else: 0
          symbol.setPixel(x, y, pixelValue)
      
      # Verify dimensions
      doAssert symbol.width == width, fmt"Symbol should be {width}x{height}"
      doAssert symbol.height == height, fmt"Symbol should be {width}x{height}"
      
      # Verify some pixels are set
      var hasPixels = false
      for x in 0..<width:
        for y in 0..<height:
          if symbol.getPixel(x, y) != 0:
            hasPixels = true
            break
      
      doAssert hasPixels == true, fmt"Symbol {width}x{height} should have pixels"

  # Test symbol dictionary indexing
  block SymbolDictionaryIndexing:
    # Create a symbol dictionary
    let symbols = @[
      newJBIG2Bitmap(16, 16, 100),
      newJBIG2Bitmap(16, 16, 200),
      newJBIG2Bitmap(16, 16, 300),
      newJBIG2Bitmap(16, 16, 400)
    ]
    
    # Fill with different patterns
    for i, symbol in symbols:
      for x in 0..<16:
        for y in 0..<16:
          var pixelValue: int
          case i
          of 0: pixelValue = if x mod 2 == 0: 1 else: 0          # Vertical stripes
          of 1: pixelValue = if y mod 2 == 0: 1 else: 0          # Horizontal stripes
          of 2: pixelValue = if (x + y) mod 2 == 0: 1 else: 0   # Checkerboard
          of 3: pixelValue = if x == y: 1 else: 0                # Diagonal
          else: pixelValue = 0
          symbol.setPixel(x, y, pixelValue)
    
    # Test indexing
    doAssert symbols[0].bitmapNumber == 100, "First symbol should have bitmap number 100"
    doAssert symbols[1].bitmapNumber == 200, "Second symbol should have bitmap number 200"
    doAssert symbols[2].bitmapNumber == 300, "Third symbol should have bitmap number 300"
    doAssert symbols[3].bitmapNumber == 400, "Fourth symbol should have bitmap number 400"
    
    # Verify patterns are different
    doAssert symbols[0].getPixel(0, 0) == 1, "First symbol should have vertical stripes"
    doAssert symbols[1].getPixel(0, 0) == 1, "Second symbol should have horizontal stripes"
    doAssert symbols[2].getPixel(0, 0) == 1, "Third symbol should have checkerboard"
    doAssert symbols[3].getPixel(0, 0) == 1, "Fourth symbol should have diagonal"
