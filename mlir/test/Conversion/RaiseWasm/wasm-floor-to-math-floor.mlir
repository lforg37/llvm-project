// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s

module {
  wasm.func nested @func_0() -> f64 {
    %0 = wasm.const -1.210000e+01 : f64
    %1 = wasm.floor %0 : f64
    wasm.return %1 : f64
  }
  wasm.func nested @func_1() -> f32 {
    %0 = wasm.const 1.618000e+00 : f32
    %1 = wasm.floor %0 : f32
    wasm.return %1 : f32
  }
}

// CHECK-LABEL:   func.func @func_0() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1.210000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = math.floor %[[VAL_0]] : f64
// CHECK:           return %[[VAL_1]] : f64

// CHECK-LABEL:   func.func @func_1() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 1.618000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = math.floor %[[VAL_0]] : f32
// CHECK:           return %[[VAL_1]] : f32
