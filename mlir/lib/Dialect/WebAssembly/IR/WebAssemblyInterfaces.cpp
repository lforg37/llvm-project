//===- WebAssemblyInterfaces.cpp - WebAssembly Interfaces -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines op interfaces for the WebAssembly dialect in MLIR.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Visitors.h"

namespace mlir {
namespace wasm {
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.cpp.inc"

LogicalResult
detail::verifyConstantExpressionInterface(Operation *op) {
  Region &initializerRegion = op->getRegion(0);
  auto resultState = initializerRegion.walk(
      [&](Operation *currentOp) -> WalkResult {
        if (isa<ReturnOp>(currentOp))
            return WalkResult::advance();
        if (auto interfaceOp = dyn_cast<WasmConstantExprCheckInterface>(currentOp)){
            if(interfaceOp.isValidInConstantExpr().succeeded())
                return WalkResult::advance();
        }
        op->emitError("Expected a constant initializer for this operator, got ") << currentOp;
        return WalkResult::interrupt();
      });
  return success(!resultState.wasInterrupted());
}

} // namespace wasm
} // namespace mlir
