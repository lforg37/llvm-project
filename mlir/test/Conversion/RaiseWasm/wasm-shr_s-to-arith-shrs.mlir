// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// CHECK-LABEL:   func.func @shr_s_i32(
// CHECK-SAME:      %[[VAL_0:.*]]: i32,
// CHECK-SAME:      %[[VAL_1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_2:.*]] = arith.shrsi %[[VAL_0]], %[[VAL_1]] : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.func nested @shr_s_i32(%arg0: i32, %arg1: i32) -> i32 {
    %op = wasm.shr_s %arg0 by %arg1 bits : i32
    wasm.return %op : i32
}

// CHECK-LABEL:   func.func @shr_s_i64(
// CHECK-SAME:      %[[VAL_0:.*]]: i64,
// CHECK-SAME:      %[[VAL_1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_2:.*]] = arith.shrsi %[[VAL_0]], %[[VAL_1]] : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.func nested @shr_s_i64(%arg0: i64, %arg1: i64) -> i64 {
    %op = wasm.shr_s %arg0 by %arg1 bits : i64
    wasm.return %op : i64
}
