// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// CHECK-LABEL:   func.func @max_f32(
// CHECK-SAME:      %[[VAL_0:.*]]: f32,
// CHECK-SAME:      %[[VAL_1:.*]]: f32) -> f32 {
// CHECK:           %[[VAL_2:.*]] = arith.maximumf %[[VAL_0]], %[[VAL_1]] : f32
// CHECK:           return %[[VAL_2]] : f32
wasm.func nested @max_f32(%arg0: f32, %arg1: f32) -> f32 {
    %op = wasm.max %arg0 %arg1 : f32
    wasm.return %op : f32
}

// CHECK-LABEL:   func.func @max_f64(
// CHECK-SAME:      %[[VAL_0:.*]]: f64,
// CHECK-SAME:      %[[VAL_1:.*]]: f64) -> f64 {
// CHECK:           %[[VAL_2:.*]] = arith.maximumf %[[VAL_0]], %[[VAL_1]] : f64
// CHECK:           return %[[VAL_2]] : f64
wasm.func nested @max_f64(%arg0: f64, %arg1: f64) -> f64 {
    %op = wasm.max %arg0 %arg1 : f64
    wasm.return %op : f64
}
