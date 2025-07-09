//===- WasmMLIRToEmbedder.cpp - Convert Wasm to stuff ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements lowering of wasm operations to standard dialects ops.
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/WasmMLIRToEmbedder/WasmMLIRToEmbedder.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/IR/Types.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/Transforms/Passes.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/LogicalResult.h"
#include <string>

#define DEBUG_TYPE "wasm-convert"

namespace mlir {
#define GEN_PASS_DEF_WASMMLIRTOEMBEDDER
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::wasm;

namespace {

static Region *getGlobalRegion(Operation *op) {
  auto *currentReg = op->getParentRegion();
  while (currentReg->getParentRegion() != nullptr)
    currentReg = currentReg->getParentRegion();
  return currentReg;
}

static StringLiteral getTypeString(mlir::Type t) {
  if (t.isF32())
    return "f32";
  if (t.isF64())
    return "f64";
  if (t.isInteger(32))
    return "i32";
  if (t.isInteger(64))
    return "i64";
  llvm_unreachable("unsupported datatype by the wasm spec");
}

template <typename SourceOp>
struct TrappableOpConversion : OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SourceOp srcOp, typename SourceOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    MLIRContext *ctx = srcOp.getContext();
    auto *symTable = SymbolTable::getNearestSymbolTable(srcOp);
    auto opName = srcOp.getOperationName();
    auto typeName = getTypeString(srcOp.getResult().getType());
    std::string symbolName = opName.str() + "_" + typeName.str();
    if (!symTable)
      return failure();
    if (!SymbolTable::lookupSymbolIn(symTable, symbolName)) {
      auto ip = rewriter.saveInsertionPoint();
      auto *globRegion = getGlobalRegion(srcOp);
      rewriter.setInsertionPoint(&globRegion->getBlocks().begin()->front());
      auto funcDec = rewriter.create<func::FuncOp>(
          globRegion->getLoc(), symbolName,
          FunctionType::get(ctx, srcOp->getOperandTypes(),
                            srcOp->getResultTypes()));
      SymbolTable::setSymbolVisibility(funcDec,
                                       SymbolTable::Visibility::Private);
      rewriter.restoreInsertionPoint(ip);
    }
    rewriter.replaceOpWithNewOp<func::CallOp>(
        srcOp, symbolName, srcOp.getResult().getType(), srcOp.getOperands());

    return success();
  }
};

using WasmAddConversion = TrappableOpConversion<AddOp>;
using WasmDivConversion = TrappableOpConversion<DivOp>;
using WasmDivUIConversion = TrappableOpConversion<DivUIOp>;
using WasmDivSIConversion = TrappableOpConversion<DivSIOp>;
using WasmMulConversion = TrappableOpConversion<MulOp>;
using WasmSubConversion = TrappableOpConversion<SubOp>;

struct WasmMLIRToEmbedderPass
    : public impl::WasmMLIRToEmbedderBase<WasmMLIRToEmbedderPass> {
  void runOnOperation() override {
    ConversionTarget target{getContext()};
    RewritePatternSet patterns(&getContext());
    target.addLegalDialect<arith::ArithDialect, BuiltinDialect,
                           cf::ControlFlowDialect, func::FuncDialect,
                           memref::MemRefDialect, math::MathDialect>();
    TypeConverter tc{};
    tc.addConversion([](Type type) -> std::optional<Type> { return type; });
    populateWasmMLIRToEmbedderConversionPatterns(tc, patterns);
    auto *head = getOperation();
    if (failed(applyFullConversion(head, target, std::move(patterns))))
      return signalPassFailure();
  }
};
} // namespace

void mlir::populateWasmMLIRToEmbedderConversionPatterns(
    TypeConverter &tc, RewritePatternSet &patternSet) {
  auto *ctx = patternSet.getContext();
  // Disable clang-format in patternSet for readability + small diffs.
  // clang-format off
  patternSet.add<
      WasmAddConversion,
      WasmDivConversion,
      WasmDivSIConversion,
      WasmDivUIConversion,
      WasmMulConversion,
      WasmSubConversion
  >(tc, ctx);
  // clang-format on
}

std::unique_ptr<Pass> mlir::createWasmMLIRToEmbedderPass() {
  return std::make_unique<WasmMLIRToEmbedderPass>();
}
