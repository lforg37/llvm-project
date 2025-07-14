add_mlir_conversion_library(MLIRWasmSSAToEmbedder
  WasmSSAMLIRToEmbedder.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Conversion/WasmSSAMLIRToEmbedder

  DEPENDS
  MLIRConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRFuncDialect
  MLIRTransforms
  MLIRWasmSSADialect
  )
