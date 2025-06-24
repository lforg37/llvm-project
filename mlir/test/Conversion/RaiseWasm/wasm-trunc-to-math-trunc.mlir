// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

module {
  wasm.func nested @func_4() -> f64 {
    %0 = wasm.const -1.210000e+01 : f64
    %1 = wasm.trunc %0 : f64
    wasm.return %1 : f64
  }
  wasm.func nested @func_5() -> f32 {
    %0 = wasm.const 1.618000e+00 : f32
    %1 = wasm.trunc %0 : f32
    wasm.return %1 : f32
  }
}

// CHECK-LABEL:   func.func @func_4() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1.210000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = math.trunc %[[VAL_0]] : f64
// CHECK:           return %[[VAL_1]] : f64

// CHECK-LABEL:   func.func @func_5() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 1.618000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = math.trunc %[[VAL_0]] : f32
// CHECK:           return %[[VAL_1]] : f32

