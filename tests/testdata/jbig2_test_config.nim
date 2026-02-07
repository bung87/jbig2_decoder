## Test configuration and resource loading utilities

import std/[os, streams, strformat, strutils]

proc getTestResourcePath*(filename: string): string =
  ## Get the full path to a test resource file
  let currentDir = currentSourcePath().parentDir
  result = currentDir / filename

proc loadTestResource*(filename: string): seq[byte] =
  ## Load a test resource file as a sequence of bytes
  let resourcePath = getTestResourcePath(filename)
  
  doAssert fileExists(resourcePath)

  
  var stream = newFileStream(resourcePath, fmRead)
  if stream == nil:
    echo fmt"Warning: Could not open test resource '{filename}'"
    return @[]
  
  let fileSize = getFileSize(resourcePath)
  result = newSeq[byte](fileSize)
  discard stream.readData(result[0].addr, result.len)
  stream.close()

proc loadJBIG2TestFile*(filename: string): seq[byte] =
  ## Load a JBIG2 test file from the images directory
  result = loadTestResource("images/" & filename)

proc loadJBIG2GitHubFile*(filename: string): seq[byte] =
  ## Load a JBIG2 GitHub issue test file
  result = loadTestResource("jbig2/" & filename)

proc loadArithmeticTestData*(filename: string): seq[byte] =
  ## Load arithmetic decoder test data
  result = loadTestResource("arithmetic/" & filename)

proc getAvailableTestFiles*(): seq[string] =
  ## Get a list of available JBIG2 test files
  let imagesDir = getTestResourcePath("images")
  let jbig2Dir = getTestResourcePath("jbig2")
  
  result = @[]
  
  if dirExists(imagesDir):
    for kind, path in walkDir(imagesDir):
      if kind == pcFile and path.endsWith(".jb2"):
        result.add("images/" & path.splitFile().name & ".jb2")
  
  if dirExists(jbig2Dir):
    for kind, path in walkDir(jbig2Dir):
      if kind == pcFile and path.endsWith(".jb2"):
        result.add("jbig2/" & path.splitFile().name & ".jb2")

proc hasTestResource*(filename: string): bool =
  ## Check if a test resource exists
  let resourcePath = getTestResourcePath(filename)
  result = fileExists(resourcePath)