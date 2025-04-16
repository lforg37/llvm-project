//===- WebAssembly.h - WebAssembly dialect ------------------------*- C++-*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_WEBASSEMBLY_IR_WEBASSEMBLY_H_
#define MLIR_DIALECT_WEBASSEMBLY_IR_WEBASSEMBLY_H_


#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Dialect.h"

//===----------------------------------------------------------------------===//
// WebAssemblyDialect
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOpsDialect.h.inc"


//===----------------------------------------------------------------------===//
// WebAssembly Dialect Operations
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOps.h.inc"

#endif // MLIR_DIALECT_WEBASSEMBLY_IR_WEBASSEMBLY_H_
