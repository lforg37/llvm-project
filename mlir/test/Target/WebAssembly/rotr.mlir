// RUN: mlir-translate --import-wasm %S/inputs/rotr.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "rotr_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.rotr)

    (func (export "rotr_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.rotr)
)
*/

// CHECK-LABEL: wasm.func @rotr_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.rotr %0 by %1 bits : i32
// CHECK:    wasm.return %2 : i32

// CHECK-LABEL: wasm.func @rotr_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.rotr %0 by %1 bits : i64
// CHECK:    wasm.return %2 : i64


