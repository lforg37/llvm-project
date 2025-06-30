// RUN: mlir-opt %s -verify-diagnostics

module {
  // expected-error@+1 {{Expected a constant initializer for this operator}}
  wasm.global @illegal i32 mutable : {
    %0 = wasm.const 17: i32
    %1 = wasm.const 35: i32
    %2 = wasm.add %0 %1 : i32
    wasm.return %2 : i32
  }
}
