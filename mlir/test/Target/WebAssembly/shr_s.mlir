// RUN: mlir-translate --import-wasm %S/inputs/shr_s.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "shr_s_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.shr_s)

    (func (export "shr_s_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.shr_s)
)
*/

// CHECK-LABEL: wasm.func @shr_s_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.shr_s %0 by %1 bits : i32
// CHECK:    wasm.return %2 : i32

// CHECK-LABEL: wasm.func @shr_s_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.shr_s %0 by %1 bits : i64
// CHECK:    wasm.return %2 : i64


