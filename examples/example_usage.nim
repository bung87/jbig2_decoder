## Example usage of JBig2Decoder
import std/[os, sequtils, strformat]
import ../src/jbig2_decoder

proc exampleUsage() =
  echo "JBIG2 Decoder Example"
  echo "===================="
  
  # Example 1: Simple decoding
  echo "\n1. Simple JBIG2 decoding:"
  echo "   let decoder = newJBIG2Decoder()"
  echo "   let imageData = readFile(\"input.jbig2\")"
  echo "   let decodedData = decodeJBIG2(imageData, TIFF)"
  echo "   writeFile(\"output.tiff\", decodedData)"
  
  # Example 2: Working with segments
  echo "\n2. Working with JBIG2 segments:"
  echo "   let decoder = newJBIG2Decoder()"
  echo "   decoder.enableDebug(true)"
  echo "   let imageData = readFile(\"input.jbig2\")"
  echo "   discard decoder.decodeJBIG2(imageData)"
  echo "   echo \"Number of segments: \", decoder.getAllSegments().len"
  
  # Example 3: Working with bitmaps
  echo "\n3. Working with JBIG2 bitmaps:"
  echo "   let bitmap = newJBIG2Bitmap(200, 300, 1)"
  echo "   bitmap.setPixel(100, 150, true)"
  echo "   let pixelValue = bitmap.getPixel(100, 150)"
  echo "   let bitmapData = bitmap.getData()"
  echo "   echo \"Bitmap size: \", bitmapData.len, \" bytes\""
  
  # Example 4: Multi-page documents
  echo "\n4. Working with multi-page documents:"
  echo "   let decoder = newJBIG2Decoder()"
  echo "   let imageData = readFile(\"multipage.jbig2\")"
  echo "   discard decoder.decodeJBIG2(imageData)"
  echo "   echo \"Pages: \", decoder.getNumberOfPages()"
  echo "   for page in 1..decoder.getNumberOfPages():"
  echo "     let pageBitmap = decoder.getPageAsJBIG2Bitmap(page)"
  echo "     if pageBitmap != nil:"
  echo "       echo fmt\"Page {page}: {pageBitmap.getWidth()}x{pageBitmap.getHeight()}\""

proc createSampleJBIG2Data(): seq[byte] =
  ## Create a minimal JBIG2 file for testing
  ## This creates a simple header and some basic data
  result = newSeq[byte]()
  
  # JBIG2 file header
  result.add(0x97)  # Magic bytes
  result.add(0x4A)
  result.add(0x42)
  result.add(0x32)
  result.add(0x0D)  # CR
  result.add(0x0A)  # LF
  result.add(0x1A)  # EOF char
  result.add(0x0A)  # LF
  
  # File header flags (sequential organization, pages known)
  result.add(0x00)
  
  # Number of pages (1 page)
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)
  result.add(0x01)
  
  # Page information segment
  # Segment number
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)
  result.add(0x01)
  
  # Segment header flags (page information)
  result.add(PAGE_INFORMATION.byte)
  
  # Referred-to segment count and retention flags
  result.add(0x00)
  
  # Page association
  result.add(0x01)
  
  # Segment data length (placeholder)
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)
  result.add(0x20)  # 32 bytes of data
  
  # Page information data (simplified)
  result.add(0x00)
  result.add(0x64)  # Width: 100
  result.add(0x00)
  result.add(0x64)  # Height: 100
  
  # Resolution and other page info data...
  for i in 0..<28:
    result.add(0x00)
  
  # End of file segment
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)
  result.add(0x02)  # Segment number
  result.add(END_OF_FILE.byte)
  result.add(0x00)
  result.add(0x01)
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)
  result.add(0x00)

proc testWithSampleData() =
  echo "\n5. Testing with sample JBIG2 data:"
  
  let sampleData = createSampleJBIG2Data()
  echo fmt"   Created sample data: {sampleData.len} bytes"
  
  let decoder = newJBIG2Decoder()
  decoder.enableDebug(false)  # Disable debug for cleaner output
  
  try:
    let result = decoder.decodeJBIG2(sampleData)
    echo fmt"   Decoded successfully: {result.len} bytes output"
    echo "   Sample JBIG2 data processed (placeholder implementation)"
  except:
    echo "   Sample data test failed: ", getCurrentExceptionMsg()

when isMainModule:
  exampleUsage()
  testWithSampleData()
  
  echo "\nExample completed!"
  echo "To use this library in your project:"
  echo "  import jbig2_decoder"
  echo "  let decoder = newJBIG2Decoder()"
  echo "  let imageData = readFile(\"yourfile.jbig2\")"
  echo "  let decoded = decodeJBIG2(imageData)"