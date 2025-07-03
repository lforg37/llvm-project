// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// CHECK-LABEL:   func.func @max_f32(
// CHECK-SAME:      %[[ARG0:.*]]: f32,
// CHECK-SAME:      %[[ARG1:.*]]: f32) -> f32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_4:.*]] = arith.maximumf %[[VAL_2]], %[[VAL_3]] : f32
// CHECK:           return %[[VAL_4]] : f32
wasm.func nested @max_f32(%arg0: !wasm<local ref to f32>, %arg1: !wasm<local ref to f32>) -> f32 {
    %v0 = wasm.local_get %arg0 : ref to f32
    %v1 = wasm.local_get %arg1 : ref to f32
    %op = wasm.max %v0 %v1 : f32
    wasm.return %op : f32
}

// CHECK-LABEL:   func.func @max_f64(
// CHECK-SAME:      %[[ARG0:.*]]: f64,
// CHECK-SAME:      %[[ARG1:.*]]: f64) -> f64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_4:.*]] = arith.maximumf %[[VAL_2]], %[[VAL_3]] : f64
// CHECK:           return %[[VAL_4]] : f64
wasm.func nested @max_f64(%arg0: !wasm<local ref to f64>, %arg1: !wasm<local ref to f64>) -> f64 {
    %v0 = wasm.local_get %arg0 : ref to f64
    %v1 = wasm.local_get %arg1 : ref to f64
    %op = wasm.max %v0 %v1 : f64
    wasm.return %op : f64
}