set(LLVM_TARGET_DEFINITIONS WebAssemblyOps.td)

add_mlir_dialect(WebAssemblyOps wasm)
add_mlir_doc(WebAssemblyOps WebAssemblyOps Dialects/ -gen-dialect-doc)
