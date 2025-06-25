// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s

// CHECK-LABEL:   func.func @promote_f32_to_f64() -> f64 {
wasm.func @promote_f32_to_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 3.140000e+00 : f32
  %0 = wasm.const 3.14 : f32
// CHECK:           %[[VAL_1:.*]] = arith.extf %[[VAL_0]] : f32 to f64
  %1 = wasm.promote %0 : f32 to f64
// CHECK:           return %[[VAL_1]] : f64
  wasm.return %1 : f64
}
