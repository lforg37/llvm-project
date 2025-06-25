// RUN: mlir-translate --import-wasm %S/inputs/reinterpret.wasm | FileCheck %s

/*
Test generated from:
(module
    (func (export "i32.reinterpret_f32") (result i32)
        f32.const -1
        i32.reinterpret_f32
    )

    (func (export "i64.reinterpret_f64") (result i64)
        f64.const -1
        i64.reinterpret_f64
    )

    (func (export "f32.reinterpret_i32") (result f32)
        i32.const -1
        f32.reinterpret_i32
    )

    (func (export "f64.reinterpret_i64") (result f64)
        i64.const -1
        f64.reinterpret_i64
    )
)
*/

// CHECK-LABEL:   wasm.func @i32.reinterpret_f32() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.reinterpret_f32 %[[VAL_0]] : f32 to i32
// CHECK:           wasm.return %[[VAL_1]] : i32

// CHECK-LABEL:   wasm.func @i64.reinterpret_f64() -> i64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.reinterpret_f64 %[[VAL_0]] : f64 to i64
// CHECK:           wasm.return %[[VAL_1]] : i64

// CHECK-LABEL:   wasm.func @f32.reinterpret_i32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.reinterpret_i32 %[[VAL_0]] : i32 to f32
// CHECK:           wasm.return %[[VAL_1]] : f32

// CHECK-LABEL:   wasm.func @f64.reinterpret_i64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.reinterpret_i64 %[[VAL_0]] : i64 to f64
// CHECK:           wasm.return %[[VAL_1]] : f64