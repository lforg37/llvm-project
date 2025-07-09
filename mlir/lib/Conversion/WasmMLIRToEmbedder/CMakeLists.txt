add_mlir_conversion_library(MLIRWasmToEmbedder
  WasmMLIRToEmbedder.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Conversion/WasmMLIRToEmbedder

  DEPENDS
  MLIRConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRFuncDialect
  MLIRTransforms
  MLIRWasmDialect
  )
