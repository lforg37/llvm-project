// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir --wasm-mlir-to-embedder | FileCheck %s

// CHECK-LABEL:   func.func private @wasm.div_ui_i64(i64, i64) -> i64
// CHECK:         func.func private @wasm.div_ui_i32(i32, i32) -> i32
// CHECK:         func.func private @wasm.div_si_i64(i64, i64) -> i64
// CHECK:         func.func private @wasm.div_si_i32(i32, i32) -> i32

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
// CHECK:           %[[VAL_4:.*]] = call @wasm.div_si_i32(%[[VAL_2]], %[[VAL_3]]) : (i32, i32) -> i32
// CHECK:           return %[[VAL_4]] : i32

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
// CHECK:           %[[VAL_4:.*]] = call @wasm.div_si_i64(%[[VAL_2]], %[[VAL_3]]) : (i64, i64) -> i64
// CHECK:           return %[[VAL_4]] : i64

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
// CHECK:           %[[VAL_4:.*]] = call @wasm.div_ui_i32(%[[VAL_2]], %[[VAL_3]]) : (i32, i32) -> i32
// CHECK:           return %[[VAL_4]] : i32

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
// CHECK:           %[[VAL_4:.*]] = call @wasm.div_ui_i64(%[[VAL_2]], %[[VAL_3]]) : (i64, i64) -> i64
// CHECK:           return %[[VAL_4]] : i64
