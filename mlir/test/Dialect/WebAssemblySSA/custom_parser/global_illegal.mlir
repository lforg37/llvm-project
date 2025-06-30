// RUN: mlir-opt %s -verify-diagnostics

module {
  // expected-error@+1 {{Expected a constant initializer for this operator}}
  wasmssa.global @illegal i32 mutable : {
    %0 = wasmssa.const 17: i32
    %1 = wasmssa.const 35: i32
    %2 = wasmssa.add %0 %1 : i32
    wasmssa.return %2 : i32
  }
}
