// RUN: mlir-opt --split-input-file %s --convert-wasm-to-standard | FileCheck %s

// CHECK-LABEL:   func.func @func_1(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32,
// CHECK-SAME:                      %[[VAL_1:.*]]: i32) -> i32 {
wasm.func nested @func_1(%arg0: i32, %arg1: i32) -> i32 {
// CHECK:           %[[VAL_2:.*]] = arith.muli %[[VAL_0]], %[[VAL_1]] : i32
%0 = wasm.mul %arg0 %arg1 : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.return %0 : i32
}

// -----

// CHECK-LABEL:   func.func @func_2(
// CHECK-SAME:                      %[[VAL_0:.*]]: i64,
// CHECK-SAME:                      %[[VAL_1:.*]]: i64) -> i64 {
wasm.func nested @func_2(%arg0: i64, %arg1: i64) -> i64 {
// CHECK:           %[[VAL_2:.*]] = arith.muli %[[VAL_0]], %[[VAL_1]] : i64
%0 = wasm.mul %arg0 %arg1 : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.return %0 : i64
}

// -----

// CHECK-LABEL:   func.func @func_3(
// CHECK-SAME:                      %[[VAL_0:.*]]: f32,
// CHECK-SAME:                      %[[VAL_1:.*]]: f32) -> f32 {
wasm.func nested @func_3(%arg0: f32, %arg1: f32) -> f32 {
// CHECK:           %[[VAL_2:.*]] = arith.mulf %[[VAL_0]], %[[VAL_1]] : f32
%0 = wasm.mul %arg0 %arg1 : f32
// CHECK:           return %[[VAL_2]] : f32
wasm.return %0 : f32
}

// -----

// CHECK-LABEL:   func.func @func_4(
// CHECK-SAME:                      %[[VAL_0:.*]]: f64,
// CHECK-SAME:                      %[[VAL_1:.*]]: f64) -> f64 {
wasm.func nested @func_4(%arg0: f64, %arg1: f64) -> f64 {
// CHECK:           %[[VAL_2:.*]] = arith.mulf %[[VAL_0]], %[[VAL_1]] : f64
%0 = wasm.mul %arg0 %arg1 : f64
// CHECK:           return %[[VAL_2]] : f64
wasm.return %0 : f64
}
