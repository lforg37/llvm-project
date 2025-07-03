set(LLVM_LINK_COMPONENTS
  Passes
  AllTargetsCodeGens
  AllTargetsDescs
  AllTargetsInfos
  TargetParser
)

include_directories(${LLVM_MAIN_SRC_DIR}/../mlir/include)
include_directories(${CMAKE_BINARY_DIR}/tools/mlir/include)

add_llvm_executable(wasabi WasmToIR.cpp)

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)
get_property(extension_libs GLOBAL PROPERTY MLIR_EXTENSION_LIBS)

mlir_target_link_libraries(wasabi PRIVATE
  ${dialect_libs}
  ${conversion_libs}
  ${extension_libs}
  MLIRDialect
  MLIRIR
  MLIRParser
  MLIRPass
  MLIRTargetWasmImport
  MLIRTransforms
  MLIRTranslateLib
  MLIRWasmSSADialect
  MLIRWasmRaise
  MLIRToLLVMIRTranslationRegistration
)
