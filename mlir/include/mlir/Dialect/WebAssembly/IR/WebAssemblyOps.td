//===- WebAssemblyOps.td - WebAssembly op definitions ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef WEBASSEMBLY_OPS
#define WEBASSEMBLY_OPS


include "mlir/Dialect/WebAssembly/IR/WebAssemblyBase.td"
include "mlir/Dialect/WebAssembly/IR/WebAssemblyTypes.td"

include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"

class Wasm_Op<string mnemonic, list<Trait> traits = []> :
    Op<Wasm_Dialect, mnemonic, traits>;

def Wasm_FuncOp : Wasm_Op<"func", [
  AffineScope, AutomaticAllocationScope,
  DeclareOpInterfaceMethods<FunctionOpInterface>, IsolatedFromAbove]> {
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_FuncTypeAttr: $functionType,
                     OptionalAttr<StrAttr>:$sym_visibility,
                     OptionalAttr<DictArrayAttr>:$arg_attrs,
                     OptionalAttr<DictArrayAttr>:$res_attrs);
  let regions = (region AnyRegion: $body);
  let extraClassDeclaration = [{
    //===------------------------------------------------------------------===//
    // FunctionOpInterface Methods
    //===------------------------------------------------------------------===//

    /// Returns the region on the current operation that is callable. This may
    /// return null in the case of an external callable object, e.g. an external
    /// function.
    ::mlir::Region *getCallableRegion() { return isExternal() ? nullptr : &getBody(); }

    /// Returns the argument types of this function.
    ArrayRef<Type> getArgumentTypes() { return getFunctionType().getInputs(); }

    /// Returns the result types of this function.
    ArrayRef<Type> getResultTypes() { return getFunctionType().getResults(); }
  }];

  let builders = [
    OpBuilder<(ins "llvm::StringRef":$symbol, "FunctionType":$funcType )>
  ];
}

def Wasm_FuncImportOp : Wasm_Op<"import_func", [Symbol]> {
  let summary = "Importing a function variable";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_FuncTypeAttr: $type);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
}

def Wasm_GlobalOp : Wasm_Op<"global", [
  AffineScope, AutomaticAllocationScope,
  IsolatedFromAbove, Symbol]> {
  let summary= "WebAssembly global value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_ValTypeAttr: $type,
                     UnitAttr: $isMutable,
                     UnitAttr: $isExported);
  let description = [{
    WebAssembly global variable.
    Body contains the initialization instructions for the variable value.
  }];
  let regions = (region AnyRegion: $initializer);
}

def Wasm_GlobalImportOp : Wasm_Op<"import_global", [Symbol]> {
  let summary = "Importing a global variable";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_ValTypeAttr: $type,
                     UnitAttr: $isMutable);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
}

def Wasm_MemOp : Wasm_Op<"memory", [Symbol]> {
  let summary= "WebAssembly memory definition";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_LimitTypeAttr: $limits,
                     UnitAttr: $isExported);
}

def Wasm_MemImportOp : Wasm_Op<"import_mem", [Symbol]> {
  let summary = "Importing a memory";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_LimitTypeAttr: $limits);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
}

def Wasm_TableOp : Wasm_Op<"table", [Symbol]> {
  let summary= "WebAssembly table value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_TableTypeAttr: $type,
                     UnitAttr: $isExported);
}

def Wasm_TableImportOp : Wasm_Op<"import_table", [Symbol]> {
  let summary = "Importing a table";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_TableTypeAttr: $type);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
}

#endif // WEBASSEMBLY_OPS
