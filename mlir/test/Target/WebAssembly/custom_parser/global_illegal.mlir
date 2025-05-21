// RUN: mlir-opt %s -verify-diagnostics

module {
  // expected-error@+1 {{Expected a constant initializer for this operator}}
  wasm.global @illegal i32 mutable : {
    %0 = wasm.local i32
    wasm.return %0 : i32
  }
}
