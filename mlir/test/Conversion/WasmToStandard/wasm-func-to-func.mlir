// RUN: mlir-opt %s --convert-wasm-to-standard | FileCheck %s


// CHECK-LABEL:   func.func @callee(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) -> i32 {
"wasm.func"() <{functionType = (i32) -> i32, sym_name = "callee", sym_visibility = "nested"}> ({
^bb0(%arg0: i32):
// CHECK-NEXT:           return %[[VAL_0]] : i32
wasm.return %arg0 : i32
}) : () -> ()

// CHECK-LABEL:   func.func @caller(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) -> i32 {
"wasm.func"() <{functionType = (i32) -> i32, sym_name = "caller", sym_visibility = "nested"}> ({
^bb0(%arg0: i32):
// CHECK:           %[[VAL_1:.*]] = call @callee(%[[VAL_0]]) : (i32) -> i32
%0 = wasm.call @callee (%arg0) : (i32) -> i32
// CHECK:           return %[[VAL_1]] : i32
wasm.return %0 : i32
}) : () -> ()
