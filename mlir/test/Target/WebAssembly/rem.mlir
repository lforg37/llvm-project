// RUN: yaml2obj %S/inputs/rem.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "rem_u_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.rem_u)

    (func (export "rem_u_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.rem_u)

    (func (export "rem_s_i32") (result i32)
    i32.const 10
    i32.const 3
    i32.rem_s)

    (func (export "rem_s_i64") (result i64)
    i64.const 10
    i64.const 3
    i64.rem_s)
)
*/

// CHECK-LABEL: wasm.func @rem_u_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.rem_ui %0 %1 : i32
// CHECK:    wasm.return %2 : i32
// CHECK:  }

// CHECK-LABEL: wasm.func @rem_u_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.rem_ui %0 %1 : i64
// CHECK:    wasm.return %2 : i64
// CHECK:  }

// CHECK-LABEL:  wasm.func @rem_s_i32() -> i32 {
// CHECK:    %0 = wasm.const 10 : i32
// CHECK:    %1 = wasm.const 3 : i32
// CHECK:    %2 = wasm.rem_si %0 %1 : i32
// CHECK:    wasm.return %2 : i32
// CHECK:  }

// CHECK-LABEL:  wasm.func @rem_s_i64() -> i64 {
// CHECK:    %0 = wasm.const 10 : i64
// CHECK:    %1 = wasm.const 3 : i64
// CHECK:    %2 = wasm.rem_si %0 %1 : i64
// CHECK:    wasm.return %2 : i64
// CHECK:  }
