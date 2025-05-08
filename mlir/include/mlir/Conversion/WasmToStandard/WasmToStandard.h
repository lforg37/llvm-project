//===- WasmToStandard.h - Convert wasm to standard dialects ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_WaASMTOSTANDARD_WASMTOSTANDARD_H
#define MLIR_CONVERSION_WaASMTOSTANDARD_WASMTOSTANDARD_H

#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/DialectConversion.h"

namespace mlir {
class Pass;
class RewritePatternSet;

#define GEN_PASS_DECL_CONVERTWASMTOSTANDARD
#include "mlir/Conversion/Passes.h.inc"

/// Collect a set of patterns to convert from the Wasm dialect to standard dialects.
void populateWasmToStandardConversionPatterns(TypeConverter&, RewritePatternSet &);

/// Create a pass to convert ops from WasmDialect to standard dialects.
std::unique_ptr<Pass> createConvertWasmToStandardPass();

} // namespace mlir

#endif // MLIR_CONVERSION_WaASMTOSTANDARD_WASMTOSTANDARD_H
