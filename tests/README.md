# JBIG2 Decoder Test Suite

This directory contains comprehensive tests for the JBIG2 decoder library, following the structure and patterns established in the original Java implementation.

## Test Organization

The tests are organized to mirror the source code structure:

```
tests/
├── decoder/              # Decoder algorithm tests
│   ├── arithmetic/       # Arithmetic decoder tests
│   └── mmr/              # MMR decoder tests
├── image/                # Image/bitmap operation tests
├── segments/              # Segment processing tests
├── util/                  # Utility function tests
├── resources/             # Test data files
│   ├── jbig2/            # JBIG2 test files
│   └── arithmetic/       # Arithmetic test data
├── test_config.nim        # Test configuration and utilities
└── all_tests.nim         # Main test runner
```

## Running Tests

### Run all tests:
```bash
nim c -r tests/all_tests.nim
```

### Run specific test categories:
```bash
nim c -r tests/decoder/arithmetic/arithmetic_decoder_test.nim
nim c -r tests/image/bitmap_test.nim
nim c -r tests/segments/generic_region_test.nim
```

### Run with verbose output:
```bash
nim c -r tests/all_tests.nim -d:verbose
```

## Test Categories

### Decoder Tests
- **Arithmetic Decoder**: Tests arithmetic coding algorithms with trace data validation
- **MMR Decoder**: Tests Modified Modified READ compression/decompression

### Image Tests
- **Bitmap Operations**: Tests pixel manipulation, byte conversion, and bitmap transformations
- **Checksum Validation**: Tests bitmap integrity validation

### Segment Tests
- **Generic Regions**: Tests generic region decoding with various templates
- **Text Regions**: Tests text region processing and symbol placement
- **Halftone Regions**: Tests halftone pattern processing
- **Symbol Dictionaries**: Tests symbol dictionary management
- **Page Information**: Tests page metadata parsing

### Utility Tests
- **Cache Operations**: Tests soft reference caching mechanisms
- **Service Lookup**: Tests service provider interface functionality

## Test Data

The `tests/testdata/` directory contains:
- Sample JBIG2 files (`.jb2` format)
- Arithmetic encoding test sequences
- Expected output files for validation
- GitHub issue regression test cases

