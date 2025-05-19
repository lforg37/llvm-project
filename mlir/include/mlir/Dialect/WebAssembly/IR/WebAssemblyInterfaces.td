//===-- WebAssemblyInterfaces.td - WebAssembly Interfaces --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines interfaces for the WebAssembly dialect in MLIR.
//
//===----------------------------------------------------------------------===//

#ifndef WEBASSEMBLY_INTERFACES
#define WEBASSEMBLY_INTERFACES

include "mlir/IR/OpBase.td"
include "mlir/IR/BuiltinAttributes.td"

def WasmImportOpInterface : OpInterface<"WasmImportOpInterface"> {
  let description = [{
    Operation that imports a symbol from an external wasm module;
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/        "Returns the module name for the import",
      /*returnType=*/  "::llvm::StringRef",
      /*methodName=*/  "getModuleName",
      /*args=*/        (ins),
      /*methodBody=*/  [{}],
      /*defaultImpl=*/ [{
        auto op = mlir::cast<ConcreteOp>(this->getOperation());
        return op.getModuleName();
      }]
      >,
    InterfaceMethod<
      /*desc=*/        "Returns the import name for the import",
      /*returnType=*/  "::llvm::StringRef",
      /*methodName=*/  "getImportName",
      /*args=*/        (ins),
      /*methodBody=*/  [{}],
      /*defaultImpl=*/ [{
        auto op = mlir::cast<ConcreteOp>(this->getOperation());
        return op.getImportName();
      }]
      >,
    InterfaceMethod<
      /*desc=*/        "Returns the wasm index based symbol of the op",
      /*returnType=*/  "::mlir::StringAttr",
      /*methodName=*/  "getSymbolName",
      /*args=*/        (ins),
      /*methodBody=*/  [{}],
      /*defaultImpl=*/ [{
        auto op = mlir::cast<ConcreteOp>(this->getOperation());
        return op.getSymbolName();
      }]
      >,
    InterfaceMethod<
      /*desc=*/        "Returns the qualified name of the import",
      /*returnType=*/  "std::string",
      /*methodName=*/  "getQualifiedImportName",
      /*args=*/        (ins),
      /*methodBody=*/  [{
        return ($_op.getModuleName() + llvm::Twine{"::"} + $_op.getImportName()).str();
      }]
      >,
  ];
}

#endif // WEBASSEMBLY_INTERFACES
