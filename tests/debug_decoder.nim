## Debug test for JBIG2 decoder
import std/[strutils, strformat]
import jbig2_decoder
import testdata/jbig2_test_config

# Simple test file
const testFile = "20123110001.jb2"

proc main() =
  let fileData = loadJBIG2TestFile(testFile)
  echo fmt"File size: {fileData.len} bytes"

  let decoder = newJBIG2StreamDecoder()
  decoder.debug = true
  discard decoder.decodeJBIG2(fileData)

  let pageBitmap = decoder.getPageAsJBIG2Bitmap(1)
  if pageBitmap == nil:
    echo "ERROR: No page bitmap found!"
    return

  echo fmt"Bitmap dimensions: {pageBitmap.width} x {pageBitmap.height}"

  let bitmapData = pageBitmap.getData(true)  # switchPixelColor=true
  echo fmt"Bitmap data size: {bitmapData.len} bytes"

  # Compute and display checksum
  var checksumStr = ""
  for i in 0..<min(bitmapData.len, 16):  # First 16 bytes
    let byteVal = cast[int8](bitmapData[i])
    checksumStr.add($byteVal)
    checksumStr.add(" ")
  echo fmt"First 16 bytes (as signed): {checksumStr}"

  # Show some pixel values
  echo "\nPixel values at corners:"
  echo fmt"  Top-left (0,0): {pageBitmap.getPixel(0, 0)}"
  echo fmt"  Top-right ({pageBitmap.width-1},0): {pageBitmap.getPixel(pageBitmap.width-1, 0)}"
  echo fmt"  Bottom-left (0,{pageBitmap.height-1}): {pageBitmap.getPixel(0, pageBitmap.height-1)}"
  echo fmt"  Bottom-right ({pageBitmap.width-1},{pageBitmap.height-1}): {pageBitmap.getPixel(pageBitmap.width-1, pageBitmap.height-1)}"

when isMainModule:
  main()
