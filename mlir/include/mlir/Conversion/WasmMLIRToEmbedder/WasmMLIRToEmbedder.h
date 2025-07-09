//===- WasmMLIRToEmbedder.h - Convert wasm mlir ops to embedder specific constructs -*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_WASMMLIRTOEMBEDDER_WASMMLIRTOEMBEDDER_H
#define MLIR_CONVERSION_WASMMLIRTOEMBEDDER_WASMMLIRTOEMBEDDER_H

#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/DialectConversion.h"

namespace mlir {
class Pass;
class RewritePatternSet;

#define GEN_PASS_DECL_WASMMLIRTOEMBEDDER
#include "mlir/Conversion/Passes.h.inc"

/// Collect a set of patterns to convert from the Wasm dialect to embedder constructs.
void populateWasmMLIRToEmbedderConversionPatterns(TypeConverter&, RewritePatternSet &);

/// Create a pass to convert ops from WasmDialect to embedder specific constructs
std::unique_ptr<Pass> createWasmMLIRToEmbedderPass();

} // namespace mlir

#endif // MLIR_CONVERSION_WASMMLIRTOEMBEDDER_WASMMLIRTOEMBEDDER_H
