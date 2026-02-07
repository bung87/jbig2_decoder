# Test Resources Directory

This directory contains test data files for the JBIG2 decoder tests.

## Directory Structure

```
testdata/
├── jbig2/          # JBIG2 test files
├── arithmetic/     # Arithmetic coding test data
└── images/         # Reference images for validation
```

## Test Files

### JBIG2 Files (.jb2)
- `test_single_page.jb2` - Single page JBIG2 document
- `test_multi_page.jb2` - Multi-page JBIG2 document
- `test_text_region.jb2` - Document with text regions
- `test_generic_region.jb2` - Document with generic regions
- `test_halftone_region.jb2` - Document with halftone regions
- `test_corrupted.jb2` - Intentionally corrupted JBIG2 file

### Arithmetic Test Data
- `test_sequences.bin` - Test sequences for arithmetic decoder
- `trace_data.bin` - Trace data for validation

### Reference Images
- `expected_output_*.png` - Expected output images for validation
- `test_pattern_*.png` - Test patterns for various scenarios

## Usage

Test files are loaded automatically by the test framework using the `getTestResourcePath()` function from `test_config.nim`.

## Creating New Test Files

When adding new test files:
1. Place them in the appropriate subdirectory
2. Update this README with file description
3. Add corresponding tests that use the new files
4. Ensure files are committed to version control