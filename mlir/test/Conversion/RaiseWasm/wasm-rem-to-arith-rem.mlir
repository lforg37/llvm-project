// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s


// CHECK-LABEL:   func.func @rem_ui_32(
// CHECK-SAME:      %[[VAL_0:.*]]: i32,
// CHECK-SAME:      %[[VAL_1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_2:.*]] = arith.remui %[[VAL_0]], %[[VAL_1]] : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.func nested @rem_ui_32(%arg0: i32, %arg1: i32) -> i32 {
    %rem = wasm.rem_ui %arg0 %arg1 : i32
    wasm.return %rem : i32
}

// CHECK-LABEL:   func.func @rem_si_32(
// CHECK-SAME:      %[[VAL_0:.*]]: i32,
// CHECK-SAME:      %[[VAL_1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_2:.*]] = arith.remsi %[[VAL_0]], %[[VAL_1]] : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.func nested @rem_si_32(%arg0: i32, %arg1: i32) -> i32 {
    %rem = wasm.rem_si %arg0 %arg1 : i32
    wasm.return %rem : i32
}

// CHECK-LABEL:   func.func @rem_ui_64(
// CHECK-SAME:      %[[VAL_0:.*]]: i64,
// CHECK-SAME:      %[[VAL_1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_2:.*]] = arith.remui %[[VAL_0]], %[[VAL_1]] : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.func nested @rem_ui_64(%arg0: i64, %arg1: i64) -> i64 {
    %rem = wasm.rem_ui %arg0 %arg1 : i64
    wasm.return %rem : i64
}

// CHECK-LABEL:   func.func @rem_si_64(
// CHECK-SAME:      %[[VAL_0:.*]]: i64,
// CHECK-SAME:      %[[VAL_1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_2:.*]] = arith.remsi %[[VAL_0]], %[[VAL_1]] : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.func nested @rem_si_64(%arg0: i64, %arg1: i64) -> i64 {
    %rem = wasm.rem_si %arg0 %arg1 : i64
    wasm.return %rem : i64
}
