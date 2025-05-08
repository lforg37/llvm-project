//===- WasmToStandard.cpp - Convert wams to standard dialects ---*- C++ -*-===//
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

#include "mlir/Conversion/WasmToStandard/WasmToStandard.h"


#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/Transforms/Passes.h"


#include <algorithm>
#include <optional>

namespace mlir {
#define GEN_PASS_DEF_CONVERTWASMTOSTANDARD
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::wasm;

namespace {

struct WasmFuncOpConversion : OpConversionPattern<FuncOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(FuncOp funcOp, FuncOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto newFunc = rewriter.create<func::FuncOp>(
        funcOp->getLoc(), funcOp.getSymName(), funcOp.getFunctionType());
    rewriter.cloneRegionBefore(funcOp.getBody(), newFunc.getBody(),
                               newFunc.getBody().end());
    rewriter.replaceOp(funcOp, newFunc);
    return success();
  }
};

struct WasmReturnOpConversion : OpConversionPattern<ReturnOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ReturnOp returnOp, ReturnOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<func::ReturnOp>(returnOp, adaptor.getOperands());
    return success();
  }
};

struct ConvertWasmToStandardPass
    : public impl::ConvertWasmToStandardBase<ConvertWasmToStandardPass> {
  void runOnOperation() override {
    ConversionTarget target{getContext()};
    target.addIllegalDialect<WasmDialect>();
    target.addLegalDialect<BuiltinDialect, func::FuncDialect,
                            memref::MemRefDialect>();
    RewritePatternSet patterns(&getContext());
    TypeConverter tc{};
    tc.addConversion([](Type type)->std::optional<Type>{
      return type;
    });

    populateWasmToStandardConversionPatterns(tc, patterns);

    if (failed(applyFullConversion(getOperation(), target, std::move(patterns))))
      return signalPassFailure();
  }
};
} // namespace

void mlir::populateWasmToStandardConversionPatterns(
    TypeConverter &tc, RewritePatternSet &patternSet) {
  auto *ctx = patternSet.getContext();
  patternSet.add<WasmFuncOpConversion, WasmReturnOpConversion>(tc, ctx);
}
