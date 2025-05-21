#include "mlir-c/IR.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"


#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/FunctionImplementation.h"
#include "llvm/Support/Casting.h"

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


namespace {
inline LogicalResult inferTeeGetResType(ValueRange operands, ::llvm::SmallVectorImpl<Type> &inferredReturnTypes) {
  if (operands.empty())
    return failure();
  auto opType = llvm::dyn_cast<MemRefType>(operands.front().getType());
  if (!opType)
    return failure();
  inferredReturnTypes.push_back(opType.getElementType());
  return success();
}
} // namespace

Block* BlockOp::createBlock() {
  auto &block = getBody().emplaceBlock();
  for (auto input : getInputs())
    block.addArgument(input.getType(), input.getLoc());
  return &block;
}

// Custom interface overrides

LogicalResult GlobalGetOp::verifyConstantExprValidity() {
  StringRef referencedSymbol = getGlobal();
  Operation *symTableOp = getOperation()->getParentWithTrait<OpTrait::SymbolTable>();
  Operation *definitionOp = SymbolTable::lookupSymbolIn(symTableOp, referencedSymbol);
  if (!definitionOp)
    return failure();
  auto definitionImport = llvm::dyn_cast<GlobalImportOp>(definitionOp);
  if (!definitionImport || definitionImport.getIsMutable()) {
      return emitError("global.get op is considered constant if it's referring "
                       "to a import.global symbol marked non-mutable.");
  }
  return success();
}

// Custom formats

ParseResult GlobalOp::parse(OpAsmParser &parser, OperationState &result) {
  StringAttr symbolName;
  Type globalType;
  auto *ctx = parser.getContext();
  auto res = parser.parseSymbolName(
      symbolName, SymbolTable::getSymbolAttrName(), result.attributes);

  res = parser.parseType(globalType);
  result.addAttribute(getTypeAttrName(result.name), TypeAttr::get(globalType));
  std::string mutableString;
  res = parser.parseOptionalKeywordOrString(&mutableString);
  if (res.succeeded() && mutableString == "mutable")
    result.addAttribute("isMutable", UnitAttr::get(ctx));
  std::string visibilityString;
  res = parser.parseOptionalKeywordOrString(&visibilityString);
  if (res.succeeded())
    result.addAttribute("sym_visibility",
                        StringAttr::get(ctx, visibilityString));
  res = parser.parseColon();
  Region *globalInitRegion = result.addRegion();
  res = parser.parseRegion(*globalInitRegion);
  return res;
}

void GlobalOp::print(OpAsmPrinter &printer) {
  printer << " @" << getSymName().str() << " " << getType();
  if (getIsMutable())
    printer << " mutable";
  if (auto vis = getSymVisibility())
    printer << " " << *vis;
  printer << " :";
  Region &body = getRegion();
  if (!body.empty()) {
    printer << ' ';
    printer.printRegion(body, /*printEntryBlockArgs=*/false,
                        /*printBlockTerminators=*/true);
  }
}

LogicalResult LocalOp::inferReturnTypes(
    MLIRContext *context, ::std::optional<Location> location,
    ValueRange operands, DictionaryAttr attributes, OpaqueProperties properties,
    RegionRange regions, ::llvm::SmallVectorImpl<Type> &inferredReturnTypes) {
  LocalOp::GenericAdaptor<ValueRange> adaptor{operands, attributes, properties,
                                              regions};
  auto type = adaptor.getTypeAttr();
  if (!type)
      return failure();
  inferredReturnTypes.push_back(MemRefType::get({}, type.getValue()));
  return success();
}

LogicalResult LocalFromArgOp::inferReturnTypes(
    MLIRContext *context, ::std::optional<Location> location,
    ValueRange operands, DictionaryAttr attributes, OpaqueProperties properties,
    RegionRange regions, ::llvm::SmallVectorImpl<Type> &inferredReturnTypes) {
  if (operands.empty())
    return failure();
  Type opType = operands.front().getType();
  auto resType = MemRefType::get({}, opType);
  inferredReturnTypes.push_back(resType);
  return success();
}

LogicalResult LocalGetOp::inferReturnTypes(
    MLIRContext *context, ::std::optional<Location> location,
    ValueRange operands, DictionaryAttr attributes, OpaqueProperties properties,
    RegionRange regions, ::llvm::SmallVectorImpl<Type> &inferredReturnTypes) {
  return inferTeeGetResType(operands, inferredReturnTypes);
}

LogicalResult LocalTeeOp::inferReturnTypes(
    MLIRContext *context, ::std::optional<Location> location,
    ValueRange operands, DictionaryAttr attributes, OpaqueProperties properties,
    RegionRange regions, ::llvm::SmallVectorImpl<Type> &inferredReturnTypes) {
  return inferTeeGetResType(operands, inferredReturnTypes);
}

ParseResult parseImportOp(OpAsmParser &parser, OperationState &result) {
  std::string importName;
  auto *ctx = parser.getContext();
  ParseResult res = parser.parseString(&importName);
  result.addAttribute("importName", StringAttr::get(ctx, importName));

  std::string fromStr;
  res = parser.parseKeywordOrString(&fromStr);
  if (failed(res) || fromStr != "from")
    return failure();

  std::string moduleName;
  res = parser.parseString(&moduleName);
  if (failed(res))
    return failure();
  result.addAttribute("moduleName", StringAttr::get(ctx, moduleName));

  std::string asStr;
  res = parser.parseKeywordOrString(&asStr);
  if (failed(res) || asStr != "as")
    return failure ();

  StringAttr symbolName;
  res = parser.parseSymbolName(
      symbolName, SymbolTable::getSymbolAttrName(), result.attributes);
  return res;
}

ParseResult GlobalImportOp::parse(OpAsmParser &parser, OperationState &result) {
  auto *ctx = parser.getContext();
  ParseResult res = parseImportOp(parser, result);
  if (res.failed())
    return failure();
  std::string mutableOrSymVisString;
  res = parser.parseOptionalKeywordOrString(&mutableOrSymVisString);
  if (res.succeeded() && mutableOrSymVisString == "mutable") {
    result.addAttribute("isMutable", UnitAttr::get(ctx));
    res = parser.parseOptionalKeywordOrString(&mutableOrSymVisString);
  }

  if (res.succeeded())
    result.addAttribute("sym_visibility",
                        StringAttr::get(ctx, mutableOrSymVisString));
  res = parser.parseColon();

  Type importedType;
  res = parser.parseType(importedType);
  if (res.succeeded())
    result.addAttribute(getTypeAttrName(result.name), TypeAttr::get(importedType));
  return res;
}

void GlobalImportOp::print(OpAsmPrinter &printer) {
  printer << " \"" << getImportName() << "\" from \"" << getModuleName() << "\" as @" << getSymName();
  if (getIsMutable())
    printer << " mutable";
  if (auto vis = getSymVisibility())
    printer << " " << *vis;
  printer << " : " << getType();
}

ParseResult FuncOp::parse(::mlir::OpAsmParser &parser, ::mlir::OperationState &result) {
  auto buildFuncType =
      [](Builder &builder, ArrayRef<Type> argTypes, ArrayRef<Type> results,
         function_interface_impl::VariadicFlag,
         std::string &) { return builder.getFunctionType(argTypes, results); };

  return function_interface_impl::parseFunctionOp(
      parser, result, /*allowVariadic=*/false,
      getFunctionTypeAttrName(result.name), buildFuncType,
      getArgAttrsAttrName(result.name), getResAttrsAttrName(result.name));
}

void FuncOp::print(OpAsmPrinter &p) {
  function_interface_impl::printFunctionOp(
      p, *this, /*isVariadic=*/false, getFunctionTypeAttrName(),
      getArgAttrsAttrName(), getResAttrsAttrName());
}

// Custom builders

void ReturnOp::build(::mlir::OpBuilder &odsBuilder,
                     ::mlir::OperationState &odsState) {}

void mlir::wasm::FuncImportOp::build(::mlir::OpBuilder &odsBuilder,
                                     ::mlir::OperationState &odsState,
                                     StringRef symbol, StringRef moduleName,
                                     StringRef importName, FunctionType type) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("moduleName", odsBuilder.getStringAttr(moduleName));
  odsState.addAttribute("importName", odsBuilder.getStringAttr(importName));
  odsState.addAttribute("type", TypeAttr::get(type));
}

void mlir::wasm::GlobalImportOp::build(::mlir::OpBuilder &odsBuilder,
                                       ::mlir::OperationState &odsState,
                                       StringRef symbol, StringRef moduleName,
                                       StringRef importName, Type type,
                                       bool isMutable) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("moduleName", odsBuilder.getStringAttr(moduleName));
  odsState.addAttribute("importName", odsBuilder.getStringAttr(importName));
  odsState.addAttribute("type", TypeAttr::get(type));
  if (isMutable)
    odsState.addAttribute("isMutable", odsBuilder.getUnitAttr());
}

void mlir::wasm::FuncOp::build(::mlir::OpBuilder &odsBuilder,
                               ::mlir::OperationState &odsState,
                               llvm::StringRef symbol, FunctionType funcType) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("functionType", TypeAttr::get(funcType));
  odsState.addRegion();
}

void GlobalOp::build(::mlir::OpBuilder &odsBuilder,
                     ::mlir::OperationState &odsState, llvm::StringRef symbol,
                     Type type, bool isMutable) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("type", TypeAttr::get(type));
  if (isMutable)
    odsState.addAttribute("isMutable", odsBuilder.getUnitAttr());
  odsState.addRegion();
}

void MemOp::build(::mlir::OpBuilder &odsBuilder,
                  ::mlir::OperationState &odsState, llvm::StringRef symbol,
                  LimitType limit) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("limits", TypeAttr::get(limit));
}

void MemImportOp::build(mlir::OpBuilder &odsBuilder,
                        ::mlir::OperationState &odsState,
                        llvm::StringRef symbol, llvm::StringRef moduleName,
                        llvm::StringRef importName, LimitType limits) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("moduleName", odsBuilder.getStringAttr(moduleName));
  odsState.addAttribute("importName", odsBuilder.getStringAttr(importName));
  odsState.addAttribute("limits", TypeAttr::get(limits));
}

void TableOp::build(::mlir::OpBuilder &odsBuilder,
                    ::mlir::OperationState &odsState, llvm::StringRef symbol,
                    TableType type) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("type", TypeAttr::get(type));
}

void TableImportOp::build(mlir::OpBuilder &odsBuilder,
                          ::mlir::OperationState &odsState,
                          llvm::StringRef symbol, llvm::StringRef moduleName,
                          llvm::StringRef importName, TableType type) {
  odsState.addAttribute("sym_name", odsBuilder.getStringAttr(symbol));
  odsState.addAttribute("sym_visibility", odsBuilder.getStringAttr("nested"));
  odsState.addAttribute("moduleName", odsBuilder.getStringAttr(moduleName));
  odsState.addAttribute("importName", odsBuilder.getStringAttr(importName));
  odsState.addAttribute("type", TypeAttr::get(type));
}
