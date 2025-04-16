//===- TranslateFromWasm.cpp - Translating to C++ calls -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/Target/Wasm/WasmImporter.h"

using namespace mlir;

namespace mlir {
namespace wasm {
OwningOpRef<ModuleOp> importWebAssemblyToModule(llvm::SourceMgr &source,
                                                MLIRContext *context) {
  return {nullptr};
}
} // namespace wasm
} // namespace mlir
