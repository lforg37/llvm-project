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
#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/Types.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/Transforms/Passes.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/LogicalResult.h"
#include <array>
#include <string>

#define DEBUG_TYPE "wasm-convert"

namespace mlir {
#define GEN_PASS_DEF_WASMMLIRTOEMBEDDER
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::wasm;

namespace {

struct WasmRuntimeFunctionsSymbols {
  SymbolRefAttr trap;
};

template <typename SrcOp>
struct WasmRuntimeOpConversion : OpConversionPattern<SrcOp> {
  WasmRuntimeOpConversion(MLIRContext *context,
                          WasmRuntimeFunctionsSymbols const &runtimeFuncSym)
      : OpConversionPattern<SrcOp>{context}, runtimeSymbols{runtimeFuncSym} {}
  WasmRuntimeOpConversion(const TypeConverter &typeConverter,
                          MLIRContext *context,
                          WasmRuntimeFunctionsSymbols const &runtimeFuncSym)
      : OpConversionPattern<SrcOp>{typeConverter, context},
        runtimeSymbols{runtimeFuncSym} {}

public:
  WasmRuntimeFunctionsSymbols const &runtimeSymbols;
};

template<typename WasmOpType, typename ArithOpName>
struct DivOpConversion : WasmRuntimeOpConversion<WasmOpType> {
  using WasmRuntimeOpConversion<WasmOpType>::WasmRuntimeOpConversion;
  LogicalResult
  matchAndRewrite(WasmOpType divOp, typename WasmOpType::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto addResType = divOp.getResult().getType();
    auto divByZeroMarkerType = rewriter.getIntegerType(1);
    auto zero = rewriter.create<arith::ConstantOp>(
        divOp->getLoc(), rewriter.getIntegerAttr(addResType, 0));
    auto isDividerZero = rewriter.create<arith::CmpIOp>(
        divOp.getLoc(), divByZeroMarkerType, arith::CmpIPredicate::eq,
        adaptor.getRhs(), zero.getResult());
    auto *curBlock = divOp->getBlock();
    auto callTrap = rewriter.create<func::CallOp>(
        divOp->getLoc(), this->runtimeSymbols.trap, TypeRange{}, ValueRange{});
    Block *trapBlock =
        rewriter.splitBlock(curBlock, Block::iterator(callTrap.getOperation()));
    Block *normalBlock =
        rewriter.splitBlock(trapBlock, ++Block::iterator{callTrap});
    rewriter.setInsertionPointAfter(callTrap);
    rewriter.create<cf::BranchOp>(divOp->getLoc(), normalBlock);
    rewriter.setInsertionPointAfter(isDividerZero);
    rewriter.create<cf::CondBranchOp>(divOp->getLoc(), isDividerZero.getResult(),
                                      trapBlock, ValueRange{}, normalBlock,
                                      ValueRange{});
    rewriter.setInsertionPointToStart(normalBlock);
    rewriter.replaceOpWithNewOp<ArithOpName>(divOp, adaptor.getLhs(), adaptor.getRhs());
    return success();
  };
};

using DivSITrapDivZeroConversion = DivOpConversion<DivSIOp, arith::DivSIOp>;
using DivUITrapDivZeroConversion = DivOpConversion<DivUIOp, arith::DivUIOp>;

template <typename WasmOpType, typename IntrinsicOpType>
struct ArithToIntrinsicTrapOpConversion : WasmRuntimeOpConversion<WasmOpType> {
  using WasmRuntimeOpConversion<WasmOpType>::WasmRuntimeOpConversion;
  LogicalResult
  matchAndRewrite(WasmOpType wasmOp, typename WasmOpType::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (!wasmOp.getRhs().getType().isInteger())
      return rewriter.notifyMatchFailure(
          wasmOp->getLoc(),
          "This pattern handles only add operations om integer operands");
    auto addResType = wasmOp.getResult().getType();
    auto overflowMarkerType = rewriter.getIntegerType(1);
    auto intrinsicResType = LLVM::LLVMStructType::getLiteral(
        this->getContext(), {addResType, overflowMarkerType});
    auto intrinsicCall = rewriter.create<IntrinsicOpType>(
        wasmOp->getLoc(), intrinsicResType, adaptor.getLhs(), adaptor.getRhs());
    auto result =
        cast<TypedValue<LLVM::LLVMStructType>>(intrinsicCall.getResult());
    auto addResult = rewriter.create<LLVM::ExtractValueOp>(
        wasmOp->getLoc(), addResType, result,
        rewriter.getDenseI64ArrayAttr({0}));
    auto overflowMarker = rewriter.create<LLVM::ExtractValueOp>(
        wasmOp->getLoc(), overflowMarkerType, result,
        rewriter.getDenseI64ArrayAttr({1}));
    auto *curBlock = wasmOp->getBlock();
    auto callTrap = rewriter.create<func::CallOp>(
        wasmOp->getLoc(), this->runtimeSymbols.trap, TypeRange{}, ValueRange{});
    Block *trapBlock =
        rewriter.splitBlock(curBlock, Block::iterator(callTrap.getOperation()));
    Block *normalBlock =
        rewriter.splitBlock(trapBlock, ++Block::iterator{callTrap});
    rewriter.setInsertionPointAfter(callTrap);
    rewriter.create<cf::BranchOp>(wasmOp->getLoc(), normalBlock);
    rewriter.setInsertionPointAfter(overflowMarker);
    rewriter.create<cf::CondBranchOp>(wasmOp->getLoc(), overflowMarker.getRes(),
                                      trapBlock, ValueRange{}, normalBlock,
                                      ValueRange{});
    rewriter.replaceOp(wasmOp, addResult.getRes());
    return success();
  };
};

using AddOpConversion =
    ArithToIntrinsicTrapOpConversion<AddOp, LLVM::UAddWithOverflowOp>;
using MulOpConversion =
    ArithToIntrinsicTrapOpConversion<MulOp, LLVM::UMulWithOverflowOp>;
using SubOpConversion =
    ArithToIntrinsicTrapOpConversion<SubOp, LLVM::USubWithOverflowOp>;

WasmRuntimeFunctionsSymbols insertEmbedderFuncDeclarations(ModuleOp module) {
  WasmRuntimeFunctionsSymbols res;
  OpBuilder opBuilder{module.getBodyRegion()};
  auto trapDesc = opBuilder.create<func::FuncOp>(
      module.getBodyRegion().getLoc(), "wasm.trap",
      FunctionType::get(module->getContext(), TypeRange{}, TypeRange{}));
  SymbolTable::setSymbolVisibility(trapDesc, SymbolTable::Visibility::Private);
  res.trap = SymbolRefAttr::get(trapDesc);
  return res;
}

void populateWasmMLIRToEmbedderConversionPatterns(
    TypeConverter &tc, RewritePatternSet &patternSet,
    WasmRuntimeFunctionsSymbols const &runtimeSymbols) {
  auto *ctx = patternSet.getContext();
  // Disable clang-format in patternSet for readability + small diffs.
  // clang-format off
  patternSet.add<
      AddOpConversion,
      DivSITrapDivZeroConversion,
      DivUITrapDivZeroConversion,
      MulOpConversion,
      SubOpConversion
  >(tc, ctx, runtimeSymbols);
  // clang-format on
}

struct WasmMLIRToEmbedderPass
    : public impl::WasmMLIRToEmbedderBase<WasmMLIRToEmbedderPass> {
  void runOnOperation() override {
    ConversionTarget target{getContext()};
    RewritePatternSet patterns(&getContext());
    target.addLegalDialect<arith::ArithDialect, BuiltinDialect,
                           cf::ControlFlowDialect, func::FuncDialect,
                           LLVM::LLVMDialect, memref::MemRefDialect,
                           math::MathDialect>();
    TypeConverter tc{};
    tc.addConversion([](Type type) -> std::optional<Type> { return type; });
    auto module = dyn_cast<ModuleOp>(getOperation());
    if (! module)
      return signalPassFailure();
    auto runtimeSymbols = insertEmbedderFuncDeclarations(module);
    populateWasmMLIRToEmbedderConversionPatterns(tc, patterns, runtimeSymbols);
    if (failed(applyFullConversion(module, target, std::move(patterns))))
      return signalPassFailure();
  }
};
} // namespace

std::unique_ptr<Pass> mlir::createWasmMLIRToEmbedderPass() {
  return std::make_unique<WasmMLIRToEmbedderPass>();
}
