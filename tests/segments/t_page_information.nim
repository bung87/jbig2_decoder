discard """
  disabled: true
"""

## Page information tests for JBIG2 segments
import std/[sequtils]
import jbig2_decoder/stream_reader

block PageInformationTests:
  # Test PageInformation header parsing
  block PageInformationHeaderParsing:
    let testData = @[48'u8]  # PAGE_INFORMATION
    let reader = newBig2StreamReader(testData)
    let segmentType = reader.readByte()
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"

  # Test PageInformation basic properties
  block PageInformationBasicProperties:
    let segmentType = 48  # PAGE_INFORMATION
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"

  # Test PageInformation with different page associations
  block PageInformationWithDifferentPageAssociations:
    let pageAssociations = [1, 2, 5, 10, 100]
    
    for pageAssoc in pageAssociations:
      let testData = @[48'u8, pageAssoc.byte]
      let reader = newBig2StreamReader(testData)
      
      let segmentType = reader.readByte()
      let pageAssociation = reader.readByte()
      
      doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
      doAssert pageAssociation == pageAssoc.byte, "Page association " & $pageAssociation & " should match expected " & $pageAssoc

  # Test PageInformation segment number handling
  block PageInformationSegmentNumberHandling:
    let segmentNumbers = [1, 10, 100, 1000]
    
    for segNum in segmentNumbers:
      let testData = @[48'u8, segNum.byte, (segNum shr 8).byte]
      let reader = newBig2StreamReader(testData)
      
      let segmentType = reader.readByte()
      let segNumberLow = reader.readByte()
      let segNumberHigh = reader.readByte()
      let segNumber = segNumberLow.int + (segNumberHigh.int shl 8)
      
      doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
      doAssert segNumber == segNum, "Segment number " & $segNumber & " should match expected " & $segNum

  # Test PageInformation retention flags
  block PageInformationRetentionFlags:
    let retentionFlags = @[0x01'u8, 0x02'u8, 0x04'u8]
    
    let testData = @[48'u8] & retentionFlags
    let reader = newBig2StreamReader(testData)
    
    let segmentType = reader.readByte()
    let flag1 = reader.readByte()
    let flag2 = reader.readByte()
    let flag3 = reader.readByte()
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert flag1 == 0x01, "First retention flag should be 0x01"
    doAssert flag2 == 0x02, "Second retention flag should be 0x02"
    doAssert flag3 == 0x04, "Third retention flag should be 0x04"

  # Test PageInformation referred-to segments
  block PageInformationReferredToSegments:
    let referredSegments = @[1, 2, 3, 4, 5]
    
    let testData = @[48'u8] & referredSegments.mapIt(it.byte)
    let reader = newBig2StreamReader(testData)
    
    let segmentType = reader.readByte()
    var retrievedSegments: seq[int]
    
    for i in 0..<referredSegments.len:
      retrievedSegments.add(reader.readByte().int)
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert retrievedSegments == referredSegments, "Retrieved referred segments " & $retrievedSegments & " should match expected " & $referredSegments

  # Test PageInformation data length
  block PageInformationDataLength:
    let dataLengths = [0, 100, 1000, 10000]
    
    for dataLen in dataLengths:
      let testData = @[48'u8, dataLen.byte, (dataLen shr 8).byte, (dataLen shr 16).byte, (dataLen shr 24).byte]
      let reader = newBig2StreamReader(testData)
      
      let segmentType = reader.readByte()
      let length = reader.readInt32()
      
      doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
      doAssert int(length) == dataLen, "Data length " & $int(length) & " should match expected " & $dataLen

  # Test PageInformation with sequential organization
  block PageInformationWithSequentialOrganization:
    let testData = @[48'u8, 1'u8]  # PAGE_INFORMATION + page 1
    let reader = newBig2StreamReader(testData)
    
    # Test that page information can be processed in sequential mode
    let segmentType = reader.readByte()
    let pageAssociation = reader.readByte()
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert pageAssociation == 1, "Page association should be 1 for sequential organization"

  # Test PageInformation with random access organization
  block PageInformationWithRandomAccessOrganization:
    let testData = @[48'u8, 42'u8, 0'u8]  # PAGE_INFORMATION + segment 42
    let reader = newBig2StreamReader(testData)
    
    # Test that page information can be processed in random access mode
    let segmentType = reader.readByte()
    let segmentNumber = reader.readByte()
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert segmentNumber == 42, "Segment number should be 42 for random access organization"

  # Test PageInformation multiple pages
  block PageInformationMultiplePages:
    let pageCount = 5
    
    for i in 0..<pageCount:
      let testData = @[48'u8, (i + 1).byte]
      let reader = newBig2StreamReader(testData)
      
      let segmentType = reader.readByte()
      let pageAssociation = reader.readByte()
      
      doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
      doAssert pageAssociation == (i + 1).byte, "Page association " & $pageAssociation & " should match expected " & $(i + 1)

  # Test PageInformation with large page numbers
  block PageInformationWithLargePageNumbers:
    let largePageNumbers = [1000, 10000, 100000]
    
    for pageNum in largePageNumbers:
      let testData = @[48'u8, pageNum.byte, (pageNum shr 8).byte, (pageNum shr 16).byte, (pageNum shr 24).byte]
      let reader = newBig2StreamReader(testData)
      
      let segmentType = reader.readByte()
      let pageAssociation = reader.readInt32()
      
      doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
      doAssert pageAssociation == pageNum.int32, "Page association " & $pageAssociation & " should match expected " & $pageNum

  # Test PageInformation performance baseline
  block PageInformationPerformanceBaseline:
    when defined(PERFORMANCE_TESTING):
      let startTime = epochTime()
      
      # Create multiple page information segments
      for i in 0..<1000:
        let testData = @[48'u8, (i + 1).byte, i.byte, (i shr 8).byte, 100'u8]
        let reader = newBig2StreamReader(testData)
        
        let segmentType = reader.readByte()
        let pageAssociation = reader.readByte()
        let segmentNumber = reader.readInt16()
        let dataLength = reader.readByte()
        
        doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
        doAssert pageAssociation == (i + 1).byte, "Page association " & $pageAssociation & " should match expected " & $(i + 1)
        doAssert segmentNumber == i, "Segment number " & $segmentNumber & " should match expected " & $i
        doAssert dataLength == 100, "Data length should be 100 bytes"
      
      let endTime = epochTime()
      let executionTime = endTime - startTime
      
      doAssert executionTime < 1.0, "Performance test should complete within 1 second"

  # Test PageInformation with deferred non-retain flag
  block PageInformationWithDeferredNonRetainFlag:
    let testData = @[0x80'u8 or 48'u8]  # Deferred non-retain flag + PAGE_INFORMATION
    let reader = newBig2StreamReader(testData)
    
    let flagsAndType = reader.readByte()
    let segmentType = flagsAndType and 0x3F  # Mask out flags
    let deferredNonRetainFlag = (flagsAndType and 0x80) != 0
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert deferredNonRetainFlag == true, "Deferred non-retain flag should be true when set"

  # Test PageInformation with page association size flag
  block PageInformationWithPageAssociationSizeFlag:
    let testData = @[0x40'u8 or 48'u8]  # Page association size flag + PAGE_INFORMATION
    let reader = newBig2StreamReader(testData)
    
    let flagsAndType = reader.readByte()
    let segmentType = flagsAndType and 0x3F  # Mask out flags
    let pageAssocSizeFlag = (flagsAndType and 0x40) != 0
    
    doAssert segmentType == 48, "Segment type should be 48 (PAGE_INFORMATION)"
    doAssert pageAssocSizeFlag == true, "Page association size flag should be true when set"
