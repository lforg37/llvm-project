//===- WebAssemblyTypes.td - WebAssembly op definitions ----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef WEBASSEMBLY_TYPES
#define WEBASSEMBLY_TYPES

include "mlir/Dialect/WebAssembly/IR/WebAssemblyBase.td"

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/CommonAttrConstraints.td"
include "mlir/IR/CommonTypeConstraints.td"

def Wasm_IntegerType : AnyTypeOf<[I32, I64]>;
def Wasm_FPType: AnyTypeOf<[F32, F64]>;
def Wasm_NumericType : AnyTypeOf<[Wasm_IntegerType, Wasm_FPType]>;
def Wasm_VecType : AnyTypeOf<[I128]>;

class Wasm_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<Wasm_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def Wasm_FuncRefType : Wasm_Type<"FuncRef", "funcref"> {
  let summary = "Opaque type for function reference";
  let assemblyFormat = "";
}

def Wasm_ExternRefType : Wasm_Type<"ExternRef", "externref"> {
  let summary = "Opaque type for external reference";
}

def Wasm_StackType : Wasm_Type<"Stack", "stack"> {
  let summary = "Opaque type for representing a stack";
}

def Wasm_RefType : AnyTypeOf<[Wasm_FuncRefType, Wasm_ExternRefType]> {
  let cppFunctionName = "isWasmRefType";
}

def Wasm_ValType : AnyTypeOf<[Wasm_NumericType, Wasm_VecType, Wasm_RefType]>;

def Wasm_ResultType : TupleOf<[Wasm_ValType]>;

def Wasm_FuncType : TypeAlias<FunctionType>;

def Wasm_LimitType : Wasm_Type<"Limit", "limit"> {
  let summary = "Wasm limit type";
  let parameters = (ins  "uint32_t":$min,
                        "std::optional<uint32_t>":$max);
  let hasCustomAssemblyFormat = 1;
}

def Wasm_TableType : Wasm_Type<"Table", "tabletype"> {
  let summary = "Wasm table type";
  let parameters = (ins Wasm_RefType:$reference,
                       Wasm_LimitType:$limit);
  let assemblyFormat = "$reference $limit";
}


def Wasm_FuncTypeAttr : TypeAttrOf<Wasm_FuncType>;
def Wasm_LimitTypeAttr : TypeAttrOf<Wasm_LimitType>;
def Wasm_TableTypeAttr : TypeAttrOf<Wasm_TableType>;
def Wasm_ValTypeAttr : TypeAttrOf<Wasm_ValType>;

def Wasm_IntegrAttr : AnyAttrOf<[I32Attr, I64Attr]>;
def Wasm_FPAttr : AnyAttrOf<[F32Attr, F64Attr]>;
def Wasm_NumericAttr : AnyAttrOf<[Wasm_IntegrAttr, Wasm_FPAttr]>;
def Wasm_VecAttr : TypedSignlessIntegerAttrBase<
    I128, "::llvm::APInt", "128 bits signless integer attribute">;

#endif // WEBASSEMBLY_TYPES
