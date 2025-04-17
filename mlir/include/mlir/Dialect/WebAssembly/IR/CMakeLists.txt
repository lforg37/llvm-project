set(LLVM_TARGET_DEFINITIONS WebAssemblyTypes.td)
mlir_tablegen(WebAssemblyTypeConstraints.h.inc -gen-type-constraint-decls)
mlir_tablegen(WebAssemblyTypeConstraints.cpp.inc -gen-type-constraint-defs)

set(LLVM_TARGET_DEFINITIONS WebAssemblyOps.td)

add_mlir_dialect(WebAssemblyOps wasm)
add_mlir_doc(WebAssemblyOps WebAssemblyOps Dialects/ -gen-dialect-doc)
