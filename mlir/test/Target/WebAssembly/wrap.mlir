// RUN: mlir-translate --import-wasm %S/inputs/wrap.wasm | FileCheck %s
/* Source code used to create this test:
(module
    (func (export "i64_wrap") (param $in i64) (result i32)
    local.get $in
    i32.wrap_i64
    )
)
*/

// CHECK-LABEL:   wasm.func @i64_wrap(
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i64>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local_get %[[ARG0]] :  ref to i64
// CHECK:           %[[VAL_1:.*]] = wasm.wrap %[[VAL_0]] : i64 to i32
// CHECK:           wasm.return %[[VAL_1]] : i32
