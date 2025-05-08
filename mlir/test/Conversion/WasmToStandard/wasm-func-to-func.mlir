// RUN: mlir-opt %s --convert-wasm-to-standard | FileCheck %s


// CHECK-LABEL:   func.func @func_1(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) -> i32 {
"wasm.func"() <{functionType = (i32) -> i32, sym_name = "func_1", sym_visibility = "nested"}> ({
^bb0(%arg0: i32):
// CHECK-NEXT:           return %[[VAL_0]] : i32
wasm.return %arg0 : i32
}) : () -> ()
