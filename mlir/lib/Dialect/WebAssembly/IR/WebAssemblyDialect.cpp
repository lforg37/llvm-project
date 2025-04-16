//===- WebAssemblyDialect.cpp - MLIR WebAssembly dialect implementation ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"

using namespace mlir;
using namespace mlir::wasm;

#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOpsDialect.cpp.inc"

void wasm::WasmDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOps.cpp.inc"
      >();
}
