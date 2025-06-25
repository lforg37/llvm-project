// RUN: mlir-translate --import-wasm %S/inputs/trunc_float_to_int.wasm | FileCheck %s
/* Source code used to create this test:
(module
  (func $F32SI32 (result i32)
    f32.const 10.5
    i32.trunc_f32_s
    )
  (func $F32UI32 (result i32)
    f32.const 10.5
    i32.trunc_f32_u
    )
  (func $F64SI32 (result i32)
    f64.const 10.5
    i32.trunc_f64_s
    )
  (func $F64UI32 (result i32)
    f64.const 10.5
    i32.trunc_f64_u
    )
  (func $F32SI64 (result i64)
    f32.const 10.5
    i64.trunc_f32_s
    )
  (func $F32UI64 (result i64)
    f32.const 10.5
    i64.trunc_f32_u
    )
  (func $F64SI64 (result i64)
    f64.const 10.5
    i64.trunc_f64_s
    )
  (func $F64UI64 (result i64)
    f64.const 10.5
    i64.trunc_f64_u
    )
)*/

// CHECK: AAAAAAAAA
