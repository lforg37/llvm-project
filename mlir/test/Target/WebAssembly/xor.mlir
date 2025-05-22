// RUN: mlir-translate --import-wasm %S/inputs/xor.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "xor_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.xor)

    (func (export "xor_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.xor)
)
*/

// CHECK-LABEL: wasm.func @xor_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.xor %0 %1 : i32
// CHECK:    wasm.return %2 : i32

// CHECK-LABEL: wasm.func @xor_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.xor %0 %1 : i64
// CHECK:    wasm.return %2 : i64


