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
include "mlir/Dialect/WebAssembly/IR/WebAssemblyInterfaces.td"

include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"

class Wasm_Op<string mnemonic, list<Trait> traits = []> :
    Op<Wasm_Dialect, mnemonic, traits>;

def Wasm_BlockOp : Wasm_Op<"block", [Terminator,
    DeclareOpInterfaceMethods<WasmLabelLevelInterface>]> {
  let summary = "Create a nesting level";
  let arguments = (ins Variadic<Wasm_ValType>: $inputs);
  let regions = (region AnyRegion: $body);
  let successors = (successor AnySuccessor: $target);
  let extraClassDeclaration = [{
    ::mlir::Block* createBlock();
  }];
  let assemblyFormat = "(`(`$inputs^`)` `:` type($inputs))? attr-dict  `:` $body `>` $target";
}

def Wasm_BlockReturnOp : Wasm_Op<"block_return", [Terminator,
    DeclareOpInterfaceMethods<WasmLabelBranchingInterface>]> {
  let summary = "Return from the current block";
  let arguments = (ins Variadic<Wasm_ValType>: $inputs);
  let assemblyFormat = "($inputs^ `:` type($inputs))? attr-dict";
}


def Wasm_ConstOp : Wasm_Op<"const", [
    AllTypesMatch<["value", "result"]>, WasmConstantExprInterface]> {
  let summary = "Push a constant to the stack";
  let arguments = (ins TypedAttrInterface: $value);
  let results = (outs Wasm_NumericType: $result);
  let assemblyFormat = "$value attr-dict";
}

def Wasm_FuncOp : Wasm_Op<"func", [
    AffineScope, AutomaticAllocationScope,
    DeclareOpInterfaceMethods<FunctionOpInterface>,
    IsolatedFromAbove,
    Symbol]> {
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_FuncTypeAttr: $functionType,
                     OptionalAttr<DictArrayAttr>:$arg_attrs,
                     OptionalAttr<DictArrayAttr>:$res_attrs,
                     DefaultValuedAttr<StrAttr, "\"nested\"">:$sym_visibility);
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
  let hasCustomAssemblyFormat = 1;
}

def Wasm_FuncCallOp : Wasm_Op<"call"> {
  let summary = "Calling a wasm function";
  let arguments = (ins FlatSymbolRefAttr: $callee,
                       Variadic<Wasm_ValType>:  $operands);
  let results = (outs Variadic<Wasm_ValType>: $results);
  let assemblyFormat = "$callee (`(`$operands^`)`)? attr-dict `:` functional-type($operands, $results)";
  let description = [{
    Emits a call to callee. Takes a stack as input, which is used as the set of function arguments for callee.
  }];
}

def Wasm_FuncImportOp : Wasm_Op<"import_func", [
    Symbol,
    CallableOpInterface,
    WasmImportOpInterface]> {
  let summary = "Importing a function variable";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_FuncTypeAttr: $type,
                     OptionalAttr<DictArrayAttr>:$arg_attrs,
                     OptionalAttr<DictArrayAttr>:$res_attrs,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }

    Region *getCallableRegion() { return nullptr; }

    llvm::ArrayRef<Type> getArgumentTypes() {
      return getType().getInputs();
    }

    llvm::ArrayRef<Type> getResultTypes() {
      return getType().getResults();
    }
  }];
  let builders = [
    OpBuilder<(ins "StringRef":$symbol,
                   "StringRef":$moduleName,
                   "StringRef":$importName,
                   "FunctionType": $type)>
  ];
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_GlobalOp : Wasm_Op<"global", [
  AffineScope, AutomaticAllocationScope,
  IsolatedFromAbove, Symbol, WasmConstantExpressionInitializerInterface]> {
  let summary= "WebAssembly global value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_ValTypeAttr: $type,
                     UnitAttr: $isMutable,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let description = [{
    WebAssembly global variable.
    Body contains the initialization instructions for the variable value.
  }];
  let regions = (region AnyRegion: $initializer);

  let builders = [
    OpBuilder<(ins "StringRef":$symbol,
                   "Type": $type,
                   "bool": $isMutable)>
  ];
  let hasCustomAssemblyFormat = 1;
}

def Wasm_GlobalImportOp : Wasm_Op<"import_global", [
    Symbol,
    WasmImportOpInterface]> {
  let summary = "Importing a global variable";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_ValTypeAttr: $type,
                     UnitAttr: $isMutable,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
  let builders = [
    OpBuilder<(ins "StringRef":$symbol,
                   "StringRef":$moduleName,
                   "StringRef":$importName,
                   "Type": $type,
                   "bool": $isMutable)>
  ];
  let hasCustomAssemblyFormat = 1;
}

def Wasm_GlobalGetOp : Wasm_Op<"global_get", [DeclareOpInterfaceMethods<WasmContextuallyConstantExprInterface>]> {
  let summary = "Returns the value of the global passed as argument.";
  let arguments = (ins FlatSymbolRefAttr: $global);
  let results = (outs Wasm_ValType: $global_val);
  let assemblyFormat = "$global attr-dict `:` type($global_val)";
}

def Wasm_LocalOp : Wasm_Op<"local", [
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Declaration of local variable";
  let arguments = (ins Wasm_ValTypeAttr: $type);
  let results = (outs Wasm_LocalRef: $result);
  let assemblyFormat = "$type attr-dict";
}

def Wasm_LocalFromArgOp : Wasm_Op<"local_from_arg", [
    ParentOneOf<["FuncOp"]>,
    SameOperandsAndResultElementType,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Declaration of local variable storage from block argument";
  let description = [{
    Wasm locals includes the function arguments.
    As they can be overriden in different path, they should be converted to memref.
    This op is not a counterpart to any Wasm existing op.
  }];
  let arguments = (ins Wasm_ValType: $blockInput);
  let results = (outs Wasm_LocalRef: $result);
  let assemblyFormat = "$blockInput `:` type($blockInput) attr-dict";
}

def Wasm_LocalGetOp : Wasm_Op<"local_get", [
    SameOperandsAndResultElementType,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Set local to value and return the operand.";
  let arguments = (ins Wasm_LocalRef: $localVar);
  let results = (outs Wasm_ValType: $result);
  let assemblyFormat = "$localVar `:` type($localVar) attr-dict";
}

def Wasm_LocalSetOp : Wasm_Op<"local_set",[
    SameOperandsElementType]> {
  let summary = "Set local to given value";
  let arguments = (ins Wasm_LocalRef: $localVar,
                       Wasm_ValType: $value);
  let assemblyFormat = "$localVar `:` type($localVar) `to` $value `:` type($value) attr-dict";
}

def Wasm_LocalTeeOp : Wasm_Op<"local_tee", [
    SameOperandsAndResultElementType,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "Set local to value and return the operand.";
  let arguments = (ins Wasm_LocalRef: $localVar,
                       Wasm_ValType: $value);
  let results = (outs Wasm_ValType: $result);
  let assemblyFormat = "$localVar `:` type($localVar) `to` $value `:` type($value) attr-dict";
}

def Wasm_MemOp : Wasm_Op<"memory", [Symbol]> {
  let summary= "WebAssembly memory definition";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_LimitTypeAttr: $limits,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let builders = [
    OpBuilder<(ins
    "llvm::StringRef":$symbol,
    "LimitType":$limit)>
  ];
}

def Wasm_MemImportOp : Wasm_Op<"import_mem", [Symbol, WasmImportOpInterface]> {
  let summary = "Importing a memory";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_LimitTypeAttr: $limits,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let extraClassDeclaration = [{
     bool isDeclaration() const { return true; }
   }];
  let builders = [OpBuilder<(ins
    "llvm::StringRef":$symbol,
    "llvm::StringRef":$moduleName,
    "llvm::StringRef":$importName,
    "wasm::LimitType":$limits)>];
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
}

def Wasm_TableOp : Wasm_Op<"table", [Symbol]> {
  let summary= "WebAssembly table value";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     Wasm_TableTypeAttr: $type,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let builders = [OpBuilder<(ins
      "llvm::StringRef":$symbol,
      "wasm::TableType":$type)>];
}

def Wasm_TableImportOp : Wasm_Op<"import_table", [Symbol, WasmImportOpInterface]> {
  let summary = "Importing a table";
  let arguments = (ins SymbolNameAttr: $sym_name,
                     StrAttr: $moduleName,
                     StrAttr: $importName,
                     Wasm_TableTypeAttr: $type,
                     OptionalAttr<StrAttr>:$sym_visibility);
  let extraClassDeclaration = [{
    bool isDeclaration() const { return true; }
  }];
  let assemblyFormat = "$importName `from` $moduleName `as` $sym_name attr-dict";
  let builders = [OpBuilder<(ins
      "llvm::StringRef":$symbol,
      "llvm::StringRef":$moduleName,
      "llvm::StringRef":$importName,
      "wasm::TableType":$type)>];
}

def Wasm_ReturnOp : Wasm_Op<"return", [Terminator]> {
  let summary = "Return from the current function frame";
  let arguments = (ins Variadic<Wasm_ValType>:  $operands);
  let assemblyFormat = "attr-dict ($operands^ `:` type($operands))?";
  let builders = [
    OpBuilder<(ins)>
  ];
}

// ---- Numeric ops

class Wasm_BinaryNumericalOp<string mnemonic, string summaryStr,
                       list<Type> validOpTypes> :
  Wasm_Op<mnemonic, [AllTypesMatch<["lhs", "rhs", "result"]>]> {
  let summary = summaryStr;
  let arguments = (ins AnyTypeOf<validOpTypes>:$lhs, AnyTypeOf<validOpTypes>:$rhs);
  let results = (outs AnyTypeOf<validOpTypes>:$result);
  let assemblyFormat = "$lhs $rhs `:` type($lhs) attr-dict";
}

def Wasm_AddOp : Wasm_BinaryNumericalOp<"add",
    "Sum two values from the stack and push the result",
    [Wasm_NumericType]>{}

def Wasm_AndOp : Wasm_BinaryNumericalOp<"and",
    [{Consume two integers from the stack, compute the bitwise AND, and push the
    result.}],
    [Wasm_NumericType]>{}

def Wasm_DivOp : Wasm_BinaryNumericalOp<"div",
    "Divide floating point values from the stack and push the result",
    [Wasm_FPType]>{}

def Wasm_DivUIOp : Wasm_BinaryNumericalOp<"div_ui",
    "Divide values interpreted as unsigned int from the stack and push the result",
    [Wasm_IntegerType]>{}

def Wasm_DivSIOp : Wasm_BinaryNumericalOp<"div_si",
    "Divide values interpreted as signed int from the stack and push the result",
    [Wasm_IntegerType]>{}

def Wasm_MulOp : Wasm_BinaryNumericalOp<"mul",
    "Multiply two values from the stack and push the result",
    [Wasm_NumericType]>{}

def Wasm_OrOp : Wasm_BinaryNumericalOp<"or",
    [{Consume two integers from the stack, compute the bitwise OR, and push the
    result.}],
    [Wasm_NumericType]>{}

def Wasm_SubOp : Wasm_BinaryNumericalOp<"sub",
    "Subtract two values from the stack and push the result",
    [Wasm_NumericType]>{}

def Wasm_RemUIOp : Wasm_BinaryNumericalOp<"rem_ui",
    [{Calculate the remainder of dividing two integer values from the stack as
    an unsigned integer, and push the result.}],
    [Wasm_IntegerType]>{}

def Wasm_RemSIOp : Wasm_BinaryNumericalOp<"rem_si",
    [{Calculate the remainder of dividing two integer values from the stack as a
    signed integer, and push the result.}],
    [Wasm_IntegerType]>{}

def Wasm_XOrOp : Wasm_BinaryNumericalOp<"xor",
    [{Consume two integers from the stack, compute the bitwise XOR, and push the
    result.}],
    [Wasm_NumericType]>{}

def Wasm_MinOp : Wasm_BinaryNumericalOp<"min",
    [{Compute the minimum of two floating point values.}],
    [Wasm_FPType]>{}

def Wasm_MaxOp : Wasm_BinaryNumericalOp<"max",
    [{Compute the minimum of two floating point values.}],
    [Wasm_FPType]>{}

class Wasm_BinaryComparisonOp<string mnemonic, string summaryStr,
                       list<Type> validOpTypes> :
  Wasm_Op<mnemonic, [AllTypesMatch<["lhs", "rhs"]>]> {
  let summary = summaryStr;
  let arguments = (ins AnyTypeOf<validOpTypes>:$lhs, AnyTypeOf<validOpTypes>:$rhs);
  let results = (outs I32:$result);
  let assemblyFormat = "$lhs $rhs `:` type($lhs) `->` type($result) attr-dict";
}

def Wasm_EqOp : Wasm_BinaryComparisonOp<"eq",
    "Check if two values from the stack are equal and push the result",
    [Wasm_NumericType]>{}

def Wasm_NeOp : Wasm_BinaryComparisonOp<"ne",
    "Check if two values from the stack are different and push the result",
    [Wasm_NumericType]>{}

def Wasm_LtSIOp : Wasm_BinaryComparisonOp<"lt_si",
    "Check if a signed integer value is less than another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_LtUIOp : Wasm_BinaryComparisonOp<"lt_ui",
    "Check if an unsigned integer value is less than another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_LeSIOp : Wasm_BinaryComparisonOp<"le_si",
    "Check if a signed integer value is less or equal to another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_LeUIOp : Wasm_BinaryComparisonOp<"le_ui",
    "Check if an unsigned integer value is less or equal to another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_GtSIOp : Wasm_BinaryComparisonOp<"gt_si",
    "Check if a signed integer value is greater than another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_GtUIOp : Wasm_BinaryComparisonOp<"gt_ui",
    "Check if an unsigned integer value is greater than another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_GeSIOp : Wasm_BinaryComparisonOp<"ge_si",
    "Check if a signed integer value is greater or equal to another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_GeUIOp : Wasm_BinaryComparisonOp<"ge_ui",
    "Check if an unsigned integer value is greater or equal to another and push the result",
    [Wasm_IntegerType]>{}

def Wasm_LtOp : Wasm_BinaryComparisonOp<"lt",
    "Check if a float value is less than another and push the result",
    [Wasm_FPType]>{}

def Wasm_LeOp : Wasm_BinaryComparisonOp<"le",
    "Check if a float value is less or equal to another and push the result",
    [Wasm_FPType]>{}

def Wasm_GtOp : Wasm_BinaryComparisonOp<"gt",
    "Check if a float value is greater than another and push the result",
    [Wasm_FPType]>{}

def Wasm_GeOp : Wasm_BinaryComparisonOp<"ge",
    "Check if a float value is greater or equal to another and push the result",
    [Wasm_FPType]>{}

// Integer shift and rotate operations.
class Wasm_ShiftRotateOp<string mnemonic, string summaryStr> :
  Wasm_Op<mnemonic, [AllTypesMatch<["val", "bits", "result"]>]> {
  let summary = summaryStr;
  let arguments = (ins Wasm_IntegerType:$val, Wasm_IntegerType:$bits);
  let results = (outs Wasm_IntegerType:$result);
  let assemblyFormat = "$val `by` $bits `bits` `:` type($val) attr-dict";
}

def Wasm_ShLOp : Wasm_ShiftRotateOp<"shl",
    [{Consume an integer, and an integer shift amount from the stack. The first
    integer shall be shifted left by N bits, where N is the value of the second
    integer. The result will then be pushed to the stack.}]
    >{}

def Wasm_ShRSOp : Wasm_ShiftRotateOp<"shr_s",
    [{Arithmetic right shift.

    Consume an integer, and an integer shift amount from the stack. The first
    integer shall be shifted right by N bits, where N is the value of the
    second integer.

    Vacated bits on the left shall be filled with the sign bit.}]
    >{}

def Wasm_ShRUOp : Wasm_ShiftRotateOp<"shr_u",
    [{Logical right shift.

    Consume an integer, and an integer shift amount from the stack. The first
    integer shall be shifted right by N bits, where N is the value of the
    second integer.

    Vacated bits on the left shall be filled with zeroes.}]
    >{}

def Wasm_RotlOp : Wasm_ShiftRotateOp<"rotl",
    [{Rotate left.

    Consume an integer, and an integer rotate amount from the stack. The first
    integer shall be rotated left by N bits, where N is the value of the
    second integer. The result shall be pushed to the stack.}]
    >{}

def Wasm_RotrOp : Wasm_ShiftRotateOp<"rotr",
    [{Rotate right.

    Consume an integer, and an integer rotate amount from the stack. The first
    integer shall be rotated right by N bits, where N is the value of the
    second integer. The result shall be pushed to the stack.}]
    >{}

class Wasm_UnaryNumericalOp<string mnemonic,
                            string summaryStr,
                            list<Type> validOpTypes> :
  Wasm_Op<mnemonic, [AllTypesMatch<["src", "result"]>]> {
    let summary = summaryStr;
    let arguments = (ins AnyTypeOf<validOpTypes>:$src);
    let results = (outs AnyTypeOf<validOpTypes>:$result);
    let assemblyFormat = "$src`:` type($src) attr-dict";
}

def Wasm_NegOp : Wasm_UnaryNumericalOp<"neg",
                                       "Floating point negation",
                                       [Wasm_FPType]>{}

#endif // WEBASSEMBLY_OPS
