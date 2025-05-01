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
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/SymbolInterfaces.td"

class Wasm_Op<string mnemonic, list<Trait> traits = []> :
    Op<Wasm_Dialect, mnemonic, traits>;

def Wasm_ConstOp : Wasm_Op<"const", [DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Push a constant to the stack";
  let arguments = (ins Wasm_StackType: $stack, Wasm_NumericAttr: $value);
  let results = (outs Wasm_StackType: $result);
  let assemblyFormat = "$value `on` $stack attr-dict";
}

def Wasm_EmptyStackOp : Wasm_Op<"empty_stack", [DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Operation for initializing an empty stack";
  let results = (outs Wasm_StackType:$result);
  let assemblyFormat = "attr-dict";
}

def Wasm_FuncOp : Wasm_Op<"func", [
    AffineScope, AutomaticAllocationScope,
    DeclareOpInterfaceMethods<FunctionOpInterface>,
    IsolatedFromAbove,
    SymbolTable]> {
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

def Wasm_FuncCallOp : Wasm_Op<"call"> {
  let summary = "Calling a wasm function";
  let arguments = (ins SymbolRefAttr: $callee,
                       Wasm_StackType: $stack);
  let results = (outs Wasm_StackType: $result);
  let assemblyFormat = "$callee `(`$stack`)` attr-dict";
  let description = [{
    Emits a call to callee. Takes a stack as input, which is used as the set of function arguments for callee.
  }];
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
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_GlobalOp : Wasm_Op<"global", [
  AffineScope, AutomaticAllocationScope,
  IsolatedFromAbove, Symbol]> {
  let summary= "WebAssembly global value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_ValTypeAttr: $type,
                     UnitAttr: $isMutable);
  let description = [{
    WebAssembly global variable.
    Body contains the initialization instructions for the variable value.
  }];
  let regions = (region AnyRegion: $initializer);
  let hasCustomAssemblyFormat = 1;
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
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_LocalOp : Wasm_Op<"local"> {
  let summary = "Declaration of local variable";
  let results = (outs Wasm_ValType: $result);
  let assemblyFormat = "type($result) attr-dict";
}

def Wasm_LocalGetOp : Wasm_Op<"local_get", [DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Push the value of a local variable on the stack";
  let arguments = (ins Wasm_ValType: $local,
                       Wasm_StackType: $stack);
  let results = (outs Wasm_StackType: $result);
  let assemblyFormat = "$local `:` type($local) `on` $stack attr-dict";
}


def Wasm_ExportOp: Wasm_Op<"export", [Symbol]> {
  let summary = "Exports a symbol. Can be a function, a global, a memory or a table.";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     SymbolRefAttr: $local_name);
  let assemblyFormat = "$local_name `as` $sym_name attr-dict";
  let hasVerifier = 1;
}

def Wasm_MemOp : Wasm_Op<"memory", [Symbol]> {
  let summary= "WebAssembly memory definition";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_LimitTypeAttr: $limits);
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
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_TableOp : Wasm_Op<"table", [Symbol]> {
  let summary= "WebAssembly table value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_TableTypeAttr: $type);
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
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_PopOp : Wasm_Op<"pop", [Terminator]> {
  let summary = "Pop a value from the stack";
  let arguments = (ins Wasm_StackType:$stack);
  let results = (outs Wasm_ValType:$result);
  let assemblyFormat = "type($result) `from` $stack attr-dict";
}

def Wasm_ReturnOp : Wasm_Op<"return", [Terminator]> {
  let summary = "Return from the current function frame";
  let assemblyFormat = "attr-dict";
}

// ---- Numeric ops

class Wasm_NumericalOp<string mnemonic, string summaryStr,
                       list<Type> validOpTypes> :
  Wasm_Op<mnemonic> {
  let summary = summaryStr;
  let arguments = (ins TypeAttrOf<AnyTypeOf<validOpTypes>>:$operandTypes,
                       Wasm_StackType:$stack);
  let results = (outs Wasm_StackType: $result);
  let assemblyFormat = "$operandTypes $stack attr-dict";
}

def Wasm_AddOp : Wasm_NumericalOp<"add",
    "Sum two values from the stack and push the result",
    [Wasm_NumericType]>{}

def Wasm_DivUIOp : Wasm_NumericalOp<"div_ui",
    "Divide values interpreted as unsigned int from the stack and push the result",
    [Wasm_IntegerType]>{}

def Wasm_DivSIOp : Wasm_NumericalOp<"div_si",
    "Divide values interpreted as signed int from the stack and push the result",
    [Wasm_IntegerType]>{}

def Wasm_MulOp : Wasm_NumericalOp<"mul",
    "Multiply two values from the stack and push the result",
    [Wasm_NumericType]>{}

#endif // WEBASSEMBLY_OPS
