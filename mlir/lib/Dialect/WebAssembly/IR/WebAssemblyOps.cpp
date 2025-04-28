#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"


#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"

//===----------------------------------------------------------------------===//
// TableGen'd op method definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOps.cpp.inc"

void mlir::wasm::FuncOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, llvm::StringRef symbol, FunctionType funcType) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("functionType", TypeAttr::get(funcType));
  odsState.addRegion();
}
