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

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i32, sym_name = "func_0", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i32, sym_name = "func_1", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i32, sym_name = "func_2", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i32, sym_name = "func_3", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i64, sym_name = "func_4", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i64, sym_name = "func_5", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_ui %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i64, sym_name = "func_6", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> i64, sym_name = "func_7", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 0 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.div_si %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> f32, sym_name = "func_8", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 2.000000e+00 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.div %[[VAL_0]] %[[VAL_1]] : f32
// CHECK:           wasm.return %[[VAL_2]] : f32

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> f64, sym_name = "func_9", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 2.000000e+00 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.div %[[VAL_0]] %[[VAL_1]] : f64
// CHECK:           wasm.return %[[VAL_2]] : f64
