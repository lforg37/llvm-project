#include "mlir-c/IR.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"


#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/SymbolTable.h"

//===----------------------------------------------------------------------===//
// TableGen'd op method definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOps.cpp.inc"

#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/Types.h"
#include "llvm/Support/LogicalResult.h"

using namespace mlir;
using namespace mlir::wasm;

LogicalResult ExportOp::verify() {
  auto symbolName = getLocalName();
  auto* symTableOp = getOperation()->getParentWithTrait<OpTrait::SymbolTable>();
  auto* originalOp = SymbolTable::lookupSymbolIn(symTableOp, symbolName);
  if (!originalOp || originalOp->getDialect() != this->getOperation()->getDialect()) {
    emitError("Undefined symbol in export operation.");
    return failure();
  }
  return success();
}

// Custom formats

ParseResult GlobalOp::parse(OpAsmParser &parser, OperationState &result) {
  StringAttr symbolName;
  Type globalType;
  auto *ctx = parser.getContext();
  auto res = parser.parseSymbolName(symbolName, SymbolTable::getSymbolAttrName(), result.attributes);

  res = parser.parseType(globalType);
  result.addAttribute(getTypeAttrName(result.name), TypeAttr::get(globalType));
  std::string mutableString;
  res = parser.parseOptionalKeywordOrString(&mutableString);
  if (res.succeeded() && mutableString == "mutable")
      result.addAttribute("isMutable", UnitAttr::get(ctx));
  res = parser.parseColon();
  Region *globalInitRegion = result.addRegion();
  res = parser.parseRegion(*globalInitRegion);
  return res;
}

void GlobalOp::print(OpAsmPrinter & printer) {
  printer << " @" << getSymName().str() << " " << getType();
  if (getIsMutable())
    printer << " mutable";
  printer << " :";
  Region &body = getRegion();
  if (!body.empty()) {
    printer << ' ';
    printer.printRegion(body, /*printEntryBlockArgs=*/false,
                  /*printBlockTerminators=*/true);
  }
}

void mlir::wasm::FuncOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, llvm::StringRef symbol, FunctionType funcType) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("functionType", TypeAttr::get(funcType));
  odsState.addRegion();
}
