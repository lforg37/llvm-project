//===- WebAssemblyhBase.td - Base defs for wasm dialect -----*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef WEBASSEMBLY_BASE
#define WEBASSEMBLY_BASE

include "mlir/IR/EnumAttr.td"
include "mlir/IR/OpBase.td"

def Wasm_Dialect : Dialect {
  let name = "wasm";
  let cppNamespace = "::mlir::wasm";
  let description = [{
    The wasm dialect is intended to represent WebAssembly modules.
  }];
  let useDefaultTypePrinterParser = true;
}

#endif //WEBASSEMBLY_BASE
