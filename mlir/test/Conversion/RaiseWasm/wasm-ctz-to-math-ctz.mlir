// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// CHECK-LABEL:   func.func @ctz_i32(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = math.cttz %[[VAL_0]] : i32
// CHECK:           return %[[VAL_1]] : i32
wasm.func nested @ctz_i32(%arg0: i32) -> i32 {
    %op = wasm.ctz %arg0 : i32
    wasm.return %op : i32
}

// CHECK-LABEL:   func.func @ctz_i64(
// CHECK-SAME:      %[[VAL_0:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_1:.*]] = math.cttz %[[VAL_0]] : i64
// CHECK:           return %[[VAL_1]] : i64
wasm.func nested @ctz_i64(%arg0: i64) -> i64 {
    %op = wasm.ctz %arg0 : i64
    wasm.return %op : i64
}
