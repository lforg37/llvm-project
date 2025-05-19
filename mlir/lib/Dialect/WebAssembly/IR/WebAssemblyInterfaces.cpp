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

namespace mlir {
namespace wasm {
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.cpp.inc"
} // namespace wasm
} // namespace mlir
