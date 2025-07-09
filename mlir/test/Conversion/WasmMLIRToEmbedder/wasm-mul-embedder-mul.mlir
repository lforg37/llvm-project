// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir --wasm-mlir-to-embedder | FileCheck %s

wasm.func nested @mul_i32(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32
    %0 = wasm.mul %v0 %v1 : i32
    wasm.return %0 : i32
}

// CHECK-LABEL:   func.func private @wasm.mul_i32(i32, i32) -> i32

// CHECK-LABEL:   func.func @mul_i32(
// CHECK-SAME:      %[[ARG0:.*]]: i32,
// CHECK-SAME:      %[[ARG1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_4:.*]] = call @wasm.mul_i32(%[[VAL_2]], %[[VAL_3]]) : (i32, i32) -> i32
// CHECK:           return %[[VAL_4]] : i32

// -----

wasm.func nested @mul_i64(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64
    %0 = wasm.mul %v0 %v1 : i64
    wasm.return %0 : i64
}

// CHECK:         func.func private @wasm.mul_i64(i64, i64) -> i64

// CHECK-LABEL:   func.func @mul_i64(
// CHECK-SAME:      %[[ARG0:.*]]: i64,
// CHECK-SAME:      %[[ARG1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_4:.*]] = call @wasm.mul_i64(%[[VAL_2]], %[[VAL_3]]) : (i64, i64) -> i64
// CHECK:           return %[[VAL_4]] : i64

// -----

wasm.func nested @mul_f32(%arg0: !wasm<local ref to f32>, %arg1: !wasm<local ref to f32>) -> f32 {
    %v0 = wasm.local_get %arg0 : ref to f32
    %v1 = wasm.local_get %arg1 : ref to f32
    %0 = wasm.mul %v0 %v1 : f32
    wasm.return %0 : f32
}

// CHECK:         func.func private @wasm.mul_f32(f32, f32) -> f32

// CHECK-LABEL:   func.func @mul_f32(
// CHECK-SAME:      %[[ARG0:.*]]: f32,
// CHECK-SAME:      %[[ARG1:.*]]: f32) -> f32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_4:.*]] = call @wasm.mul_f32(%[[VAL_2]], %[[VAL_3]]) : (f32, f32) -> f32
// CHECK:           return %[[VAL_4]] : f32

// -----

wasm.func nested @mul_f64(%arg0: !wasm<local ref to f64>, %arg1: !wasm<local ref to f64>) -> f64 {
    %v0 = wasm.local_get %arg0 : ref to f64
    %v1 = wasm.local_get %arg1 : ref to f64
    %0 = wasm.mul %v0 %v1 : f64
    wasm.return %0 : f64
}

// CHECK:         func.func private @wasm.mul_f64(f64, f64) -> f64

// CHECK-LABEL:   func.func @mul_f64(
// CHECK-SAME:      %[[ARG0:.*]]: f64,
// CHECK-SAME:      %[[ARG1:.*]]: f64) -> f64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_4:.*]] = call @wasm.mul_f64(%[[VAL_2]], %[[VAL_3]]) : (f64, f64) -> f64
// CHECK:           return %[[VAL_4]] : f64
