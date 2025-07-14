// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

wasm.func nested @div_f32(%arg0: !wasm<local ref to f32>, %arg1: !wasm<local ref to f32>) -> f32 {
    %v0 = wasm.local_get %arg0 : ref to f32
    %v1 = wasm.local_get %arg1 : ref to f32
    %0 = wasm.div %v0 %v1 : f32
    wasm.return %0 : f32
}

// CHECK-LABEL:   func.func @div_f32(
// CHECK-SAME:      %[[ARG0:.*]]: f32,
// CHECK-SAME:      %[[ARG1:.*]]: f32) -> f32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f32>
// CHECK:           %[[VAL_4:.*]] = arith.divf %[[VAL_2]], %[[VAL_3]] : f32
// CHECK:           return %[[VAL_4]] : f32

wasm.func nested @div_f64(%arg0: !wasm<local ref to f64>, %arg1: !wasm<local ref to f64>) -> f64 {
    %v0 = wasm.local_get %arg0 : ref to f64
    %v1 = wasm.local_get %arg1 : ref to f64
    %0 = wasm.div %v0 %v1 : f64
    wasm.return %0 : f64
}

// CHECK-LABEL:   func.func @div_f64(
// CHECK-SAME:      %[[ARG0:.*]]: f64,
// CHECK-SAME:      %[[ARG1:.*]]: f64) -> f64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<f64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<f64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<f64>
// CHECK:           %[[VAL_4:.*]] = arith.divf %[[VAL_2]], %[[VAL_3]] : f64
// CHECK:           return %[[VAL_4]] : f64

wasm.func nested @div_i32_si(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32
    %0 = wasm.div_si %v0 %v1 : i32
    wasm.return %0 : i32
}

// CHECK-LABEL:   func.func @div_i32_si(
// CHECK-SAME:      %[[ARG0:.*]]: i32,
// CHECK-SAME:      %[[ARG1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_5:.*]] = arith.cmpi eq, %[[VAL_3]], %[[VAL_4]] : i32
// CHECK:           cf.cond_br %[[VAL_5]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_6:.*]] = arith.divsi %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           return %[[VAL_6]] : i32

wasm.func nested @div_i64_si(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64
    %0 = wasm.div_si %v0 %v1 : i64
    wasm.return %0 : i64
}

// CHECK-LABEL:   func.func @div_i64_si(
// CHECK-SAME:      %[[ARG0:.*]]: i64,
// CHECK-SAME:      %[[ARG1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i64
// CHECK:           %[[VAL_5:.*]] = arith.cmpi eq, %[[VAL_3]], %[[VAL_4]] : i64
// CHECK:           cf.cond_br %[[VAL_5]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_6:.*]] = arith.divsi %[[VAL_2]], %[[VAL_3]] : i64
// CHECK:           return %[[VAL_6]] : i64

wasm.func nested @div_i32_ui(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32
    %0 = wasm.div_ui %v0 %v1 : i32
    wasm.return %0 : i32
}

// CHECK-LABEL:   func.func @div_i32_ui(
// CHECK-SAME:      %[[ARG0:.*]]: i32,
// CHECK-SAME:      %[[ARG1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_5:.*]] = arith.cmpi eq, %[[VAL_3]], %[[VAL_4]] : i32
// CHECK:           cf.cond_br %[[VAL_5]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_6:.*]] = arith.divui %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           return %[[VAL_6]] : i32

wasm.func nested @div_i64_ui(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64
    %0 = wasm.div_ui %v0 %v1 : i64
    wasm.return %0 : i64
}

// CHECK-LABEL:   func.func @div_i64_ui(
// CHECK-SAME:      %[[ARG0:.*]]: i64,
// CHECK-SAME:      %[[ARG1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i64
// CHECK:           %[[VAL_5:.*]] = arith.cmpi eq, %[[VAL_3]], %[[VAL_4]] : i64
// CHECK:           cf.cond_br %[[VAL_5]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_6:.*]] = arith.divui %[[VAL_2]], %[[VAL_3]] : i64
// CHECK:           return %[[VAL_6]] : i64
