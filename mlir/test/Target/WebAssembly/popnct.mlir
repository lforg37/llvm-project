// RUN: mlir-translate --import-wasm %S/inputs/popcnt.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "popcnt_i32") (result i32)
    i32.const 10
    i32.popcnt
    )

    (func (export "popcnt_i64") (result i64)
    i64.const 10
    i64.popcnt
    )
)
*/

// CHECK-LABEL:   wasm.func @popcnt_i32() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.popcnt %[[VAL_0]] : i32
// CHECK:           wasm.return %[[VAL_1]] : i32

// CHECK-LABEL:   wasm.func @popcnt_i64() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.popcnt %[[VAL_0]] : i64
// CHECK:           wasm.return %[[VAL_1]] : i64
