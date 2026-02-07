## Common types for JBIG2 decoder

type
  ImageFormat* = enum
    JPEG,
    TIFF

  JBig2Error* = object of ValueError
    ## Base exception for JBIG2 decoder errors

  InvalidHeaderValueError* = object of JBig2Error
    ## Exception thrown when an invalid header value is encountered

  IntegerMaxValueError* = object of JBig2Error
    ## Exception thrown when an integer value exceeds the maximum allowed value
