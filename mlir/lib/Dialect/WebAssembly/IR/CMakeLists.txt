add_mlir_dialect_library(MLIRWasmDialect
  WebAssemblyOps.cpp
  WebAssemblyDialect.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/WebAssembly

  DEPENDS
  MLIRWebAssemblyOpsIncGen

  LINK_LIBS PUBLIC
  MLIRCastInterfaces
  MLIRDialect
  MLIRInferTypeOpInterface
  MLIRIR
  )
