add_mlir_conversion_library(MLIRWasmToStandard
  WasmToStandard.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Conversion/WasmToStandard

  DEPENDS
  MLIRConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRArithDialect
  MLIRFuncDialect
  MLIRTransforms
  MLIRVectorDialect
  MLIRWasmDialect
  )
