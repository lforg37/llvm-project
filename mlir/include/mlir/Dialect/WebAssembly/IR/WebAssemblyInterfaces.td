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

def WasmLabelLevelInterface : OpInterface<"WasmLabelLevelInterface"> {
  let description = [{
    Operation that defines one level of nesting for wasm branching.
    These operation region can be targeted by branch instructions.
  }];
  let methods = [
    InterfaceMethod<
      /*desc=*/        "Returns the target block address",
      /*returnType=*/  "::mlir::Block*",
      /*methodName=*/  "getLabelTarget",
      /*args=*/        (ins)
    >
  ];
}

def WasmLabelBranchingInterface : OpInterface<"WasmLabelBranchingInterface"> {
  let description = [{
    Wasm operation that targets a label for a jump.
  }];
  let methods = [
    InterfaceMethod<
      /*desc=*/        "Returns the number of context to break from",
      /*returnType=*/  "size_t",
      /*methodName=*/  "getExitLevel",
      /*args=*/        (ins)
    >,
    InterfaceMethod<
      /*desc=*/        "Returns the destination of this operation",
      /*returnType=*/  "WasmLabelLevelInterface",
      /*methodName=*/  "getTargetOp",
      /*args=*/        (ins),
      /*methodBody=*/ [{
        return *WasmLabelBranchingInterface::getTargetOpFromBlock($_op.getOperation()->getBlock(), $_op.getExitLevel());
      }]
    >,
    InterfaceMethod<
      /*desc=*/        "Return the target control flow ops that defined the label of this operation",
      /*returnType=*/  "::mlir::Block*",
      /*methodName=*/  "getTarget",
      /*args=*/        (ins),
      /*methodBody=*/  [{}],
      /*defaultImpl=*/ [{
        auto op = mlir::cast<WasmLabelBranchingInterface>(this->getOperation());
        return op.getTargetOp().getLabelTarget();
      }]
    >
  ];
  let extraClassDeclaration = [{
    static ::llvm::FailureOr<WasmLabelLevelInterface> getTargetOpFromBlock(::mlir::Block *block, uint32_t level);
  }];
  let verify = [{return verifyWasmLabelBranchingInterface($_op);}];
}

def WasmImportOpInterface : OpInterface<"WasmImportOpInterface"> {
  let description = [{
    Operation that imports a symbol from an external wasm module;
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/        "Returns the module name for the import",
      /*returnType=*/  "::llvm::StringRef",
      /*methodName=*/  "getModuleName",
      /*args=*/        (ins)
      >,
    InterfaceMethod<
      /*desc=*/        "Returns the import name for the import",
      /*returnType=*/  "::llvm::StringRef",
      /*methodName=*/  "getImportName",
      /*args=*/        (ins)
      >,
    InterfaceMethod<
      /*desc=*/        "Returns the wasm index based symbol of the op",
      /*returnType=*/  "::mlir::StringAttr",
      /*methodName=*/  "getSymbolName",
      /*args=*/        (ins),
      /*methodBody=*/  [{}],
      /*defaultImpl=*/ [{
        auto op = mlir::cast<ConcreteOp>(this->getOperation());
        return op.getSymNameAttr();
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

def WasmConstantExpressionInitializerInterface :
          OpInterface<"WasmConstantExpressionInitializerInterface"> {
  let description = [{
    Operation that must be constant initialized. This
    interface adds a verifier that checks that all ops
    within the initializer region are "constant expressions"
    as defined by the WASM standard.
  }];

  let verify = [{ return detail::verifyConstantExpressionInterface($_op); }];
}

def WasmConstantExprCheckInterface :
          OpInterface<"WasmConstantExprCheckInterface"> {
  let description = [{
    Base interface for operations that can be used in a Wasm Constant Expression.
    It shouldn't be used directly, use one of the derived instead.
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/        [{
        Returns success if the current operation is valid in a constant expression context.
      }],
      /*returnType=*/  "::mlir::LogicalResult",
      /*methodName=*/  "isValidInConstantExpr",
      /*args=*/        (ins),
      /*methodBody=*/ [{
        return $_op.verifyConstantExprValidity();
      }]
      >
  ];
}

def WasmContextuallyConstantExprInterface :
          OpInterface<"WasmContextuallyConstantExprInterface", [WasmConstantExprCheckInterface]> {
  let description = [{
    Base interface for operations that can be used in a Wasm Constant Expression
    depending on the context.
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/        [{
        Returns success if the current operation is valid in a constant expression context.
      }],
      /*returnType=*/  "::mlir::LogicalResult",
      /*methodName=*/  "verifyConstantExprValidity",
      /*args=*/        (ins)
      >
  ];
}

def WasmConstantExprInterface :
          OpInterface<"WasmConstantExprInterface", [WasmConstantExprCheckInterface]> {
  let description = [{
    Base interface for operations that can always be used in a Wasm Constant Expression.
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/        [{
        Returns success if the current operation is valid in a constant expression context.
      }],
      /*returnType=*/  "::mlir::LogicalResult",
      /*methodName=*/  "verifyConstantExprValidity",
      /*args=*/        (ins),
      /*methodBody=*/ [{}],
      /*DefaultImplementation=*/ [{ return success(); }]
      >
  ];
}

#endif // WEBASSEMBLY_INTERFACES
