// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s


// CHECK-LABEL:   func.func @callee(
// CHECK-SAME:                      %[[ARG0:.*]]: i32) -> i32 {
wasm.func nested @callee(%arg0: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.load %[[VAL_0]][] : memref<i32>
%v0 = wasm.local_get %arg0 : ref to i32
// CHECK:           return %[[VAL_1]] : i32
wasm.return %v0 : i32
}

wasm.func nested @caller(%arg0: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.load %[[VAL_0]][] : memref<i32>
%v0 = wasm.local_get %arg0 : ref to i32
// CHECK:           %[[VAL_2:.*]] = call @callee(%[[VAL_1]]) : (i32) -> i32
%0 = wasm.call @callee (%v0) : (i32) -> i32
// CHECK:           return %[[VAL_2]] : i32
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
