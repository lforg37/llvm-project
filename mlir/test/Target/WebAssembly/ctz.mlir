// RUN: mlir-translate --import-wasm %S/inputs/ctz.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "ctz_i32") (result i32)
    i32.const 10
    i32.ctz
    )

    (func (export "ctz_i64") (result i64)
    i64.const 10
    i64.ctz
    )
)
*/

// CHECK-LABEL:   wasm.func @ctz_i32() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.ctz %[[VAL_0]] : i32
// CHECK:           wasm.return %[[VAL_1]] : i32

// CHECK-LABEL:   wasm.func @ctz_i64() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.ctz %[[VAL_0]] : i64
// CHECK:           wasm.return %[[VAL_1]] : i64
