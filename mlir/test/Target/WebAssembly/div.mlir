// RUN: mlir-translate --import-wasm %S/inputs/div.wasm | FileCheck %s

/* Source code used to create this test:
(module
    (func (export "div_u_i32") (result i32)
        i32.const 10
        i32.const 2
        i32.div_u
    )

    ;; explode
    (func (export "div_u_i32_zero") (result i32)
        i32.const 10
        i32.const 0
        i32.div_u
    )

    (func (export "div_s_i32") (result i32)
        i32.const 10
        i32.const 2
        i32.div_s
    )

    ;; explode
    (func (export "div_s_i32_zero") (result i32)
        i32.const 10
        i32.const 0
        i32.div_s
    )

    (func (export "div_u_i64") (result i64)
        i64.const 10
        i64.const 2
        i64.div_u
    )

    ;; explode
    (func (export "div_u_i64_zero") (result i64)
        i64.const 10
        i64.const 0
        i64.div_u
    )

    (func (export "div_s_i64") (result i64)
        i64.const 10
        i64.const 2
        i64.div_s
    )

    ;; explode
    (func (export "div_s_i64_zero") (result i64)
        i64.const 10
        i64.const 0
        i64.div_s
    )

    (func (export "div_f32") (result f32)
        f32.const 10
        f32.const 2
        f32.div
    )

    (func (export "div_f64") (result f64)
        f64.const 10
        f64.const 2
        f64.div
    )
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_1() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_2() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_3() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_4() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i64
// CHECK:           wasm.return %[[VAL_2]] : i64

// CHECK-LABEL:   wasm.func nested @func_5() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i64
// CHECK:           wasm.return %[[VAL_2]] : i64

// CHECK-LABEL:   wasm.func nested @func_6() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i64
// CHECK:           wasm.return %[[VAL_2]] : i64

// CHECK-LABEL:   wasm.func nested @func_7() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i64
// CHECK:           wasm.return %[[VAL_2]] : i64

// CHECK-LABEL:   wasm.func nested @func_8() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2.000000e+00 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.div %[[VAL_0]] %[[VAL_1]] : f32
// CHECK:           wasm.return %[[VAL_2]] : f32

// CHECK-LABEL:   wasm.func nested @func_9() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 2.000000e+00 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.div %[[VAL_0]] %[[VAL_1]] : f64
// CHECK:           wasm.return %[[VAL_2]] : f64
