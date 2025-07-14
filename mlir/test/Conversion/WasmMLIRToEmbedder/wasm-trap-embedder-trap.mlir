// RUN: mlir-opt %s --wasm-mlir-to-embedder | FileCheck %s

module {
  func.func @func() {
    wasm.trap
    return
  }
}

// CHECK-LABEL:   func.func private @wasm.trap()

// CHECK-LABEL:   func.func @func() {
// CHECK:           call @wasm.trap() : () -> ()
// CHECK:           return
// CHECK:         }
