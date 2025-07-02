// RUN: yaml2obj %S/inputs/rotl.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "rotl_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.rotl)

    (func (export "rotl_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.rotl)
)
*/

// CHECK-LABEL: wasm.func @rotl_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.rotl %0 by %1 bits : i32
// CHECK:    wasm.return %2 : i32

// CHECK-LABEL: wasm.func @rotl_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.rotl %0 by %1 bits : i64
// CHECK:    wasm.return %2 : i64


