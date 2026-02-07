## MMR (Modified Modified READ) decoder for JBIG2 - Complete implementation based on C# reference
import ./stream_reader

const
  ccittEndOfLine* = -2
  twoDimensionalPass* = 0
  twoDimensionalHorizontal* = 1
  twoDimensionalVertical0* = 2
  twoDimensionalVerticalR1* = 3
  twoDimensionalVerticalL1* = 4
  twoDimensionalVerticalR2* = 5
  twoDimensionalVerticalL2* = 6
  twoDimensionalVerticalR3* = 7
  twoDimensionalVerticalL3* = 8

# 2D code table
const twoDimensionalTable1*: array[136, array[2, int]] = [
  [-1, -1], [-1, -1], [7, twoDimensionalVerticalL3], [7, twoDimensionalVerticalR3],
  [6, twoDimensionalVerticalL2], [6, twoDimensionalVerticalL2], [6, twoDimensionalVerticalR2], [6, twoDimensionalVerticalR2],
  [4, twoDimensionalPass], [4, twoDimensionalPass], [4, twoDimensionalPass], [4, twoDimensionalPass],
  [4, twoDimensionalPass], [4, twoDimensionalPass], [4, twoDimensionalPass], [4, twoDimensionalPass],
  [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal],
  [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal],
  [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal],
  [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal], [3, twoDimensionalHorizontal],
  [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1],
  [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1],
  [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1],
  [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1], [3, twoDimensionalVerticalL1],
  [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1],
  [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1],
  [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1],
  [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1], [3, twoDimensionalVerticalR1],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0],
  [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0], [1, twoDimensionalVertical0]
]

# White code tables
const whiteTable1*: array[64, array[2, int]] = [
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64],
  [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64],
  [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128],
  [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128]
]

const whiteTable2*: array[96, array[2, int]] = [
  [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192],
  [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664],
  [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256],
  [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256],
  [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320],
  [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320],
  [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384],
  [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384], [5, 384],
  [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448],
  [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448], [5, 448],
  [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512],
  [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512], [4, 512]
]

const whiteTable3*: array[128, array[2, int]] = [
  [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704],
  [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704], [9, 704],
  [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768],
  [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768], [9, 768],
  [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832],
  [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832], [9, 832],
  [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896],
  [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896], [9, 896],
  [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960],
  [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960], [9, 960],
  [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024],
  [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024], [9, 1024],
  [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088],
  [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088], [9, 1088],
  [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152],
  [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152], [9, 1152]
]

const whiteTable4*: array[640, array[2, int]] = [
  [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216],
  [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216],
  [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216],
  [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216], [10, 1216],
  [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280],
  [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280],
  [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280],
  [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280], [10, 1280],
  [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344],
  [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344],
  [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344],
  [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344], [10, 1344],
  [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408],
  [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408],
  [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408],
  [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408], [10, 1408],
  [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472],
  [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472],
  [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472],
  [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472], [10, 1472],
  [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536],
  [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536],
  [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536],
  [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536], [10, 1536],
  [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600],
  [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600],
  [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600],
  [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600], [10, 1600],
  [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728],
  [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728],
  [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728],
  [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728], [10, 1728],
  [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856],
  [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856],
  [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856],
  [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856], [11, 1856],
  [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920],
  [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920],
  [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920],
  [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920], [11, 1920],
  [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984],
  [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984],
  [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984],
  [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984], [12, 1984],
  [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048],
  [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048],
  [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048],
  [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048], [12, 2048],
  [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112],
  [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112],
  [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112],
  [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112], [12, 2112],
  [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176],
  [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176],
  [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176],
  [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176], [12, 2176],
  [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240],
  [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240],
  [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240],
  [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240], [12, 2240],
  [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304],
  [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304],
  [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304],
  [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304], [12, 2304],
  [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368],
  [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368],
  [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368],
  [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368], [12, 2368],
  [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432],
  [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432],
  [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432],
  [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432], [11, 2432],
  [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496],
  [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496],
  [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496],
  [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496], [11, 2496],
  [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560],
  [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560],
  [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560],
  [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560], [11, 2560]
]

# Black code tables
const blackTable1*: array[64, array[2, int]] = [
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0], [-1, -1], [12, 0],
  [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64],
  [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64], [6, 64],
  [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128],
  [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128], [5, 128]
]

const blackTable2*: array[64, array[2, int]] = [
  [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192],
  [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192], [7, 192],
  [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664],
  [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664], [7, 1664],
  [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256],
  [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256], [6, 256],
  [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320],
  [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320], [6, 320]
]

const blackTable3*: array[64, array[2, int]] = [
  [-1, -1], [-1, -1], [-1, -1], [-1, -1], [6, 9], [6, 8], [5, 7], [5, 7], [4, 6], [4, 6], [4, 6], [4, 6],
  [4, 5], [4, 5], [4, 5], [4, 5], [3, 1], [3, 1], [3, 1], [3, 1], [3, 1], [3, 1], [3, 1], [3, 1], [3, 4], [3, 4],
  [3, 4], [3, 4], [3, 4], [3, 4], [3, 4], [3, 4], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3],
  [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 3], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2],
  [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2], [2, 2]
]

type
  MMRDecoder* = ref object
    reader*: Big2StreamReader
    bufferLength*: int64
    buffer*: int64
    noOfbytesRead*: int64

proc bit32ShiftL(value: int64, shift: int): int64 =
  ## 32-bit left shift (internal use)
  result = (value shl shift) and 0xFFFFFFFF'i64

proc bit32ShiftR(value: int64, shift: int): int64 =
  ## 32-bit right shift (internal use)
  result = (value shr shift) and 0xFFFFFFFF'i64

proc newMMRDecoder*(reader: Big2StreamReader): MMRDecoder =
  ## Create new MMR decoder
  result = MMRDecoder(
    reader: reader,
    bufferLength: 0,
    buffer: 0,
    noOfbytesRead: 0
  )

proc reset*(decoder: MMRDecoder) =
  ## Reset MMR decoder state
  decoder.bufferLength = 0
  decoder.noOfbytesRead = 0
  decoder.buffer = 0

proc skipTo*(decoder: MMRDecoder, length: int64) =
  ## Skip to specified length
  while decoder.noOfbytesRead < length:
    discard decoder.reader.readByte()
    decoder.noOfbytesRead += 1

proc get24Bits*(decoder: MMRDecoder): int64 =
  ## Get 24 bits from buffer
  while decoder.bufferLength < 24:
    decoder.buffer = bit32ShiftL(decoder.buffer, 8) or (decoder.reader.readByte().int64 and 0xFF)
    decoder.bufferLength += 8
    decoder.noOfbytesRead += 1

  result = bit32ShiftR(decoder.buffer, (decoder.bufferLength - 24).int) and 0xFFFFFF

proc get2DCode*(decoder: MMRDecoder): int =
  ## Get 2D code from MMR stream
  var tuple0, tuple1: int

  if decoder.bufferLength == 0:
    decoder.buffer = (decoder.reader.readByte().int64 and 0xFF)
    decoder.bufferLength = 8
    decoder.noOfbytesRead += 1

    let lookup = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
    tuple0 = twoDimensionalTable1[lookup][0]
    tuple1 = twoDimensionalTable1[lookup][1]
  elif decoder.bufferLength == 8:
    let lookup = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
    tuple0 = twoDimensionalTable1[lookup][0]
    tuple1 = twoDimensionalTable1[lookup][1]
  else:
    var lookup = int(bit32ShiftL(decoder.buffer, (7 - decoder.bufferLength).int) and 0x7F)
    tuple0 = twoDimensionalTable1[lookup][0]
    tuple1 = twoDimensionalTable1[lookup][1]

    if tuple0 < 0 or tuple0 > decoder.bufferLength.int:
      let right = (decoder.reader.readByte().int64 and 0xFF)
      let left = bit32ShiftL(decoder.buffer, 8)
      decoder.buffer = left or right
      decoder.bufferLength += 8
      decoder.noOfbytesRead += 1

      let look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 7).int) and 0x7F)
      tuple0 = twoDimensionalTable1[look][0]
      tuple1 = twoDimensionalTable1[look][1]

  if tuple0 < 0:
    return 0

  decoder.bufferLength -= tuple0
  result = tuple1

proc getWhiteCode*(decoder: MMRDecoder): int =
  ## Get white run length code
  var tuple0, tuple1: int
  var code: int64

  if decoder.bufferLength == 0:
    decoder.buffer = (decoder.reader.readByte().int64 and 0xFF)
    decoder.bufferLength = 8
    decoder.noOfbytesRead += 1

    let look = int(bit32ShiftR(decoder.buffer, 2) and 0x3F)
    tuple0 = whiteTable1[look][0]
    tuple1 = whiteTable1[look][1]

    if tuple0 < 0:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = whiteTable2[look][0]
      tuple1 = whiteTable2[look][1]
  elif decoder.bufferLength == 8:
    let look = int(bit32ShiftR(decoder.buffer, 2) and 0x3F)
    tuple0 = whiteTable1[look][0]
    tuple1 = whiteTable1[look][1]

    if tuple0 < 0:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = whiteTable2[look][0]
      tuple1 = whiteTable2[look][1]
  else:
    var look = int(bit32ShiftL(decoder.buffer, (6 - decoder.bufferLength).int) and 0x3F)
    tuple0 = whiteTable1[look][0]
    tuple1 = whiteTable1[look][1]

    if tuple0 < 0:
      look = int(bit32ShiftL(decoder.buffer, (7 - decoder.bufferLength).int) and 0x7F)
      tuple0 = whiteTable2[look][0]
      tuple1 = whiteTable2[look][1]

    if tuple0 < 0:
      let right = (decoder.reader.readByte().int64 and 0xFF)
      let left = bit32ShiftL(decoder.buffer, 8)
      decoder.buffer = left or right
      decoder.bufferLength += 8
      decoder.noOfbytesRead += 1

      look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 6).int) and 0x3F)
      tuple0 = whiteTable1[look][0]
      tuple1 = whiteTable1[look][1]

      if tuple0 < 0:
        look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 7).int) and 0x7F)
        tuple0 = whiteTable2[look][0]
        tuple1 = whiteTable2[look][1]

  if tuple0 < 0:
    return 0

  decoder.bufferLength -= tuple0
  code = tuple1

  while code >= 64:
    if decoder.bufferLength == 0:
      decoder.buffer = (decoder.reader.readByte().int64 and 0xFF)
      decoder.bufferLength = 8
      decoder.noOfbytesRead += 1

      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = whiteTable3[look][0]
      tuple1 = whiteTable3[look][1]
    elif decoder.bufferLength == 8:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = whiteTable3[look][0]
      tuple1 = whiteTable3[look][1]
    else:
      var look = int(bit32ShiftL(decoder.buffer, (7 - decoder.bufferLength).int) and 0x7F)
      tuple0 = whiteTable3[look][0]
      tuple1 = whiteTable3[look][1]

      if tuple0 < 0 or tuple0 > decoder.bufferLength.int:
        let right = (decoder.reader.readByte().int64 and 0xFF)
        let left = bit32ShiftL(decoder.buffer, 8)
        decoder.buffer = left or right
        decoder.bufferLength += 8
        decoder.noOfbytesRead += 1

        look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 7).int) and 0x7F)
        tuple0 = whiteTable3[look][0]
        tuple1 = whiteTable3[look][1]

    if tuple0 < 0:
      return 0

    decoder.bufferLength -= tuple0
    code += tuple1

  result = code.int

proc getBlackCode*(decoder: MMRDecoder): int =
  ## Get black run length code
  var tuple0, tuple1: int
  var code: int64

  if decoder.bufferLength == 0:
    decoder.buffer = (decoder.reader.readByte().int64 and 0xFF)
    decoder.bufferLength = 8
    decoder.noOfbytesRead += 1

    let look = int(bit32ShiftR(decoder.buffer, 2) and 0x3F)
    tuple0 = blackTable1[look][0]
    tuple1 = blackTable1[look][1]

    if tuple0 < 0:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = blackTable2[look][0]
      tuple1 = blackTable2[look][1]
  elif decoder.bufferLength == 8:
    let look = int(bit32ShiftR(decoder.buffer, 2) and 0x3F)
    tuple0 = blackTable1[look][0]
    tuple1 = blackTable1[look][1]

    if tuple0 < 0:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = blackTable2[look][0]
      tuple1 = blackTable2[look][1]
  else:
    var look = int(bit32ShiftL(decoder.buffer, (6 - decoder.bufferLength).int) and 0x3F)
    tuple0 = blackTable1[look][0]
    tuple1 = blackTable1[look][1]

    if tuple0 < 0:
      look = int(bit32ShiftL(decoder.buffer, (7 - decoder.bufferLength).int) and 0x7F)
      tuple0 = blackTable2[look][0]
      tuple1 = blackTable2[look][1]

    if tuple0 < 0:
      let right = (decoder.reader.readByte().int64 and 0xFF)
      let left = bit32ShiftL(decoder.buffer, 8)
      decoder.buffer = left or right
      decoder.bufferLength += 8
      decoder.noOfbytesRead += 1

      look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 6).int) and 0x3F)
      tuple0 = blackTable1[look][0]
      tuple1 = blackTable1[look][1]

      if tuple0 < 0:
        look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 7).int) and 0x7F)
        tuple0 = blackTable2[look][0]
        tuple1 = blackTable2[look][1]

  if tuple0 < 0:
    return 0

  decoder.bufferLength -= tuple0
  code = tuple1

  while code >= 64:
    if decoder.bufferLength == 0:
      decoder.buffer = (decoder.reader.readByte().int64 and 0xFF)
      decoder.bufferLength = 8
      decoder.noOfbytesRead += 1

      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = blackTable3[look][0]
      tuple1 = blackTable3[look][1]
    elif decoder.bufferLength == 8:
      let look = int(bit32ShiftR(decoder.buffer, 1) and 0x7F)
      tuple0 = blackTable3[look][0]
      tuple1 = blackTable3[look][1]
    else:
      var look = int(bit32ShiftL(decoder.buffer, (7 - decoder.bufferLength).int) and 0x7F)
      tuple0 = blackTable3[look][0]
      tuple1 = blackTable3[look][1]

      if tuple0 < 0 or tuple0 > decoder.bufferLength.int:
        let right = (decoder.reader.readByte().int64 and 0xFF)
        let left = bit32ShiftL(decoder.buffer, 8)
        decoder.buffer = left or right
        decoder.bufferLength += 8
        decoder.noOfbytesRead += 1

        look = int(bit32ShiftR(decoder.buffer, (decoder.bufferLength - 7).int) and 0x7F)
        tuple0 = blackTable3[look][0]
        tuple1 = blackTable3[look][1]

    if tuple0 < 0:
      return 0

    decoder.bufferLength -= tuple0
    code += tuple1

  result = code.int

# Mode constants for MMR decoding
type
  MMRMode* = enum
    PassMode, HorizontalMode, VerticalMode

proc decodeRunLength*(decoder: MMRDecoder): int =
  ## Decode a run length (compatibility method)
  result = decoder.getWhiteCode()

proc decodeWhiteRun*(decoder: MMRDecoder): int =
  ## Decode white run length (compatibility method)
  result = decoder.getWhiteCode()

proc decodeBlackRun*(decoder: MMRDecoder): int =
  ## Decode black run length (compatibility method)
  result = decoder.getBlackCode()

proc getMode*(decoder: MMRDecoder): MMRMode =
  ## Get current mode (compatibility method)
  let code = decoder.get2DCode()
  case code
  of twoDimensionalPass:
    result = PassMode
  of twoDimensionalHorizontal:
    result = HorizontalMode
  else:
    result = VerticalMode

proc decodeLine*(decoder: MMRDecoder, referenceLine: seq[int], width: int): seq[int] =
  ## Decode a single line using MMR
  result = newSeq[int](width)
  var currentPos = 0
  var isWhite = true

  while currentPos < width:
    var runLength: int
    if isWhite:
      runLength = decoder.getWhiteCode()
    else:
      runLength = decoder.getBlackCode()

    if runLength <= 0:
      break

    for i in 0..<runLength:
      if currentPos + i < width:
        result[currentPos + i] = if isWhite: 0 else: 1

    currentPos += runLength
    isWhite = not isWhite

proc decodeMMRData*(decoder: MMRDecoder, width: int, height: int): seq[seq[int]] =
  ## Decode complete MMR compressed data
  result = newSeq[seq[int]](height)

  # First line is typically encoded without reference
  result[0] = decoder.decodeLine(newSeq[int](0), width)

  # Subsequent lines use previous line as reference
  for i in 1..<height:
    result[i] = decoder.decodeLine(result[i-1], width)
