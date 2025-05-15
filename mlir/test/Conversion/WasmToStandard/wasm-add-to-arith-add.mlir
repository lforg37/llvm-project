// RUN: mlir-opt --split-input-file %s --convert-wasm-to-standard | FileCheck %s

// CHECK-LABEL:   func.func @func_1(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32,
// CHECK-SAME:                      %[[VAL_1:.*]]: i32) -> i32 {
"wasm.func"() <{functionType = (i32, i32) -> i32, sym_name = "func_1", sym_visibility = "nested"}> ({
^bb0(%arg0: i32, %arg1: i32):
// CHECK:           %[[VAL_2:.*]] = arith.addi %[[VAL_0]], %[[VAL_1]] : i32
%0 = wasm.add %arg0 %arg1 : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.return %0 : i32
}) : () -> ()

// -----

// CHECK-LABEL:   func.func @func_2(
// CHECK-SAME:                      %[[VAL_0:.*]]: i64,
// CHECK-SAME:                      %[[VAL_1:.*]]: i64) -> i64 {
"wasm.func"() <{functionType = (i64, i64) -> i64, sym_name = "func_2", sym_visibility = "nested"}> ({
^bb0(%arg0: i64, %arg1: i64):
// CHECK:           %[[VAL_2:.*]] = arith.addi %[[VAL_0]], %[[VAL_1]] : i64
%0 = wasm.add %arg0 %arg1 : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.return %0 : i64
}) : () -> ()

// -----

// CHECK-LABEL:   func.func @func_3(
// CHECK-SAME:                      %[[VAL_0:.*]]: f32,
// CHECK-SAME:                      %[[VAL_1:.*]]: f32) -> f32 {
"wasm.func"() <{functionType = (f32, f32) -> f32, sym_name = "func_3", sym_visibility = "nested"}> ({
^bb0(%arg0: f32, %arg1: f32):
// CHECK:           %[[VAL_2:.*]] = arith.addf %[[VAL_0]], %[[VAL_1]] : f32
%0 = wasm.add %arg0 %arg1 : f32
// CHECK:           return %[[VAL_2]] : f32
wasm.return %0 : f32
}) : () -> ()

// -----

// CHECK-LABEL:   func.func @func_4(
// CHECK-SAME:                      %[[VAL_0:.*]]: f64,
// CHECK-SAME:                      %[[VAL_1:.*]]: f64) -> f64 {
"wasm.func"() <{functionType = (f64, f64) -> f64, sym_name = "func_4", sym_visibility = "nested"}> ({
^bb0(%arg0: f64, %arg1: f64):
// CHECK:           %[[VAL_2:.*]] = arith.addf %[[VAL_0]], %[[VAL_1]] : f64
%0 = wasm.add %arg0 %arg1 : f64
// CHECK:           return %[[VAL_2]] : f64
wasm.return %0 : f64
}) : () -> ()
