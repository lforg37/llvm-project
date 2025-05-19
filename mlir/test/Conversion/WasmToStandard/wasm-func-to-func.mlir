// RUN: mlir-opt %s --convert-wasm-to-standard | FileCheck %s


// CHECK-LABEL:   func.func @callee(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) -> i32 {
wasm.func nested @callee(%arg0: i32) -> i32 {
// CHECK-NEXT:           return %[[VAL_0]] : i32
wasm.return %arg0 : i32
}

// CHECK-LABEL:   func.func @caller(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) -> i32 {
wasm.func nested @caller(%arg0: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = call @callee(%[[VAL_0]]) : (i32) -> i32
%0 = wasm.call @callee (%arg0) : (i32) -> i32
// CHECK:           return %[[VAL_1]] : i32
wasm.return %0 : i32
}

// CHECK-LABEL:         func.func private @"my_module::foo"() -> i32
wasm.import_func "foo" from "my_module" as @func_0 {sym_visibility = "nested", type = () -> (i32)}

// CHECK-LABEL:   func.func @user_of_func0() -> i32 {
wasm.func nested @user_of_func0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = call @"my_module::foo"() : () -> i32
%0 = wasm.call @func_0 : () -> i32
// CHECK:           return %[[VAL_0]] : i32
wasm.return %0 : i32
}
