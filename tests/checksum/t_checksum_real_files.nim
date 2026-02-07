discard """
  disabled: true
"""
## Checksum validation tests for real JBIG2 files
## MD5 checksums are derived from decoded bitmap data, matching Java PDFBox JBIG2 implementation
import std/[strutils, strformat, tables]

when (NimMajor, NimMinor) < (2, 2):
  import std/md5
else:
  import checksums

import jbig2_decoder
import .. / testdata/jbig2_test_config

# Table of test files with their expected MD5 checksums (as byte array string representation)
# Format: filename -> expected checksum string (bytes concatenated as signed decimal values)
const expectedChecksums = {
  "002.jb2": "-12713-4587-92-651657111-57121-1582564895",
  "003.jb2": "-37-108-89-33-78-5019-966-96-124-9675-1-108-24",
  "005.jb2": "712610586-1224021396100112-102-77-1177851",
  "006.jb2": "-8719-116-83-83-35-3425-64-528667602154-25",
  "20123110001.jb2": "60-96-101-2458-3335024-5468-5-11068-78-80",
  "20123110002.jb2": "-28-921048181-117-48-96126-110-9-2865611113",
  "20123110003.jb2": "-3942-239351-28-56-729169-5839122-439231",
  "20123110004.jb2": "-49-101-28-20-57-4-24-17-9352104-106-118-122-122",
  "20123110005.jb2": "-48221261779-94-838820-127-114110-2-88-80-106",
  "20123110006.jb2": "81-11870-63-30124-1614-45838-53-123-41639",
  "20123110007.jb2": "12183-49124728346-29-124-9-10775-63-44116103",
  "20123110008.jb2": "15-74-49-45958458-67-2545-96-119-122-60100-35",
  "20123110009.jb2": "36115-114-28-123-3-70-87-113-4197-8512396113-65",
  "20123110010.jb2": "-109-1069-61-1576-67-43122406037-75-1091115"
}.toTable()

# Compute MD5 checksum and format as signed byte string (matching Java implementation)
proc computeMD5Checksum(data: seq[byte]): string =
  ## Computes MD5 checksum and formats as concatenated signed decimal bytes
  ## This matches the Java PDFBox implementation
  let hash = toMD5(cast[string](data))
  result = ""
  for i in 0..<hash.len:
    # Convert uint8 to signed int8 properly
    let byteVal = cast[int8](hash[i])
    result.add($byteVal)

# Test Checksum with real JBIG2 files
block ChecksumWithRealJBIG2Files:

  for testFile, expectedChecksum in expectedChecksums.pairs:
    let fileData = loadJBIG2TestFile(testFile)

    doAssert fileData.len > 0, fmt"Could not load {testFile}"

    let decoder = newJBIG2StreamDecoder()
    decoder.debug = true
    discard decoder.decodeJBIG2(fileData)

    let pageBitmap = decoder.getPageAsJBIG2Bitmap(1)
    doAssert pageBitmap != nil, fmt"No page bitmap found for {testFile}"

    let bitmapData = pageBitmap.getData(true)  # switchPixelColor=true to match C# implementation
    doAssert bitmapData.len > 0, fmt"Bitmap data for {testFile} is empty"

    let actualChecksum = computeMD5Checksum(bitmapData)

    doAssert actualChecksum == expectedChecksum, fmt"Checksum mismatch for {testFile}: expected {expectedChecksum}, got {actualChecksum}"
