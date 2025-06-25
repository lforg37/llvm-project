// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s
module {
// CHECK-LABEL:   func.func @i32.reinterpret_f32() -> i32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = arith.bitcast %[[VAL_0]] : f32 to i32
// CHECK:           return %[[VAL_1]] : i32
  wasm.func @i32.reinterpret_f32() -> i32 {
    %0 = wasm.const -1.000000e+00 : f32
    %1 = wasm.reinterpret_f32 %0 : f32 to i32
    wasm.return %1 : i32
  }

// CHECK-LABEL:   func.func @i64.reinterpret_f64() -> i64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = arith.bitcast %[[VAL_0]] : f64 to i64
// CHECK:           return %[[VAL_1]] : i64
  wasm.func @i64.reinterpret_f64() -> i64 {
    %0 = wasm.const -1.000000e+00 : f64
    %1 = wasm.reinterpret_f64 %0 : f64 to i64
    wasm.return %1 : i64
  }

// CHECK-LABEL:   func.func @f32.reinterpret_i32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1 : i32
// CHECK:           %[[VAL_1:.*]] = arith.bitcast %[[VAL_0]] : i32 to f32
// CHECK:           return %[[VAL_1]] : f32
  wasm.func @f32.reinterpret_i32() -> f32 {
    %0 = wasm.const -1 : i32
    %1 = wasm.reinterpret_i32 %0 : i32 to f32
    wasm.return %1 : f32
  }

// CHECK-LABEL:   func.func @f64.reinterpret_i64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant -1 : i64
// CHECK:           %[[VAL_1:.*]] = arith.bitcast %[[VAL_0]] : i64 to f64
// CHECK:           return %[[VAL_1]] : f64
  wasm.func @f64.reinterpret_i64() -> f64 {
    %0 = wasm.const -1 : i64
    %1 = wasm.reinterpret_i64 %0 : i64 to f64
    wasm.return %1 : f64
  }
}
