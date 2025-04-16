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
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/Transforms/Passes.h"


#include <algorithm>
#include <optional>

namespace mlir {
#define GEN_PASS_DEF_CONVERTWASMTOSTANDARD
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;

namespace {
struct ConvertWasmToStandardPass
    : public impl::ConvertWasmToStandardBase<ConvertWasmToStandardPass> {
  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    populateWasmToStandardConversionPatterns(patterns);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      return signalPassFailure();
  }
};
} // namespace

void mlir::populateWasmToStandardConversionPatterns(
    RewritePatternSet &) {
}
