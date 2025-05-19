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
// WebAssembly Dialect Types
//===----------------------------------------------------------------------===//

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOpsTypes.h.inc"


//===----------------------------------------------------------------------===//
// WebAssembly Interfaces
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.h"

//===----------------------------------------------------------------------===//
// WebAssembly Dialect Operations
//===----------------------------------------------------------------------===//
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/IR/SymbolTable.h"


//===----------------------------------------------------------------------===//
// WebAssembly Constraints
//===----------------------------------------------------------------------===//

namespace mlir{
namespace wasm {
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyTypeConstraints.h.inc"
}
}// namespace mlir

#define GET_OP_CLASSES
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyOps.h.inc"

#endif // MLIR_DIALECT_WEBASSEMBLY_IR_WEBASSEMBLY_H_
