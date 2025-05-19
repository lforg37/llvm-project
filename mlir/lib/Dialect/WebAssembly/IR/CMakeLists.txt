add_mlir_dialect_library(MLIRWasmDialect
  WebAssemblyOps.cpp
  WebAssemblyDialect.cpp
  WebAssemblyInterfaces.cpp
  WebAssemblyTypes.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/WebAssembly

  DEPENDS
  MLIRWebAssemblyOpsIncGen
  MLIRWebAssemblyInterfacesIncGen

  LINK_LIBS PUBLIC
  MLIRCastInterfaces
  MLIRDataLayoutInterfaces
  MLIRDialect
  MLIRInferTypeOpInterface
  MLIRIR
  MLIRSupport
  )
