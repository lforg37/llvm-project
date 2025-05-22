// RUN: mlir-translate --import-wasm %S/inputs/comparison_ops.wasm | FileCheck %s
/* Source code used to create this test:
(module
    (func $lt_si32 (result i32)
        i32.const 12
        i32.const 50
        i32.lt_s
    )
    (func $le_si32 (result i32)
        i32.const 12
        i32.const 50
        i32.le_s
    )
    (func $lt_ui32 (result i32)
        i32.const 12
        i32.const 50
        i32.lt_u
    )
    (func $le_ui32 (result i32)
        i32.const 12
        i32.const 50
        i32.le_u
    )
    (func $gt_si32 (result i32)
        i32.const 12
        i32.const 50
        i32.gt_s
    )
    (func $gt_ui32 (result i32)
        i32.const 12
        i32.const 50
        i32.gt_u
    )
    (func $ge_si32 (result i32)
        i32.const 12
        i32.const 50
        i32.ge_s
    )
    (func $ge_ui32 (result i32)
        i32.const 12
        i32.const 50
        i32.ge_u
    )
    (func $lt_si64 (result i32)
        i64.const 12
        i64.const 50
        i64.lt_s
    )
    (func $le_si64 (result i32)
        i64.const 12
        i64.const 50
        i64.le_s
    )
    (func $lt_ui64 (result i32)
        i64.const 12
        i64.const 50
        i64.lt_u
    )
    (func $le_ui64 (result i32)
        i64.const 12
        i64.const 50
        i64.le_u
    )
    (func $gt_si64 (result i32)
        i64.const 12
        i64.const 50
        i64.gt_s
    )
    (func $gt_ui64 (result i32)
        i64.const 12
        i64.const 50
        i64.gt_u
    )
    (func $ge_si64 (result i32)
        i64.const 12
        i64.const 50
        i64.ge_s
    )
    (func $ge_ui64 (result i32)
        i64.const 12
        i64.const 50
        i64.ge_u
    )
    (func $lt_f32 (result i32)
        f32.const 5
        f32.const 14
        f32.lt
    )
    (func $le_f32 (result i32)
        f32.const 5
        f32.const 14
        f32.le
    )
    (func $gt_f32 (result i32)
        f32.const 5
        f32.const 14
        f32.gt
    )
    (func $ge_f32 (result i32)
        f32.const 5
        f32.const 14
        f32.ge
    )
    (func $lt_f64 (result i32)
        f64.const 5
        f64.const 14
        f64.lt
    )
    (func $le_f64 (result i32)
        f64.const 5
        f64.const 14
        f64.le
    )
    (func $gt_f64 (result i32)
        f64.const 5
        f64.const 14
        f64.gt
    )
    (func $ge_f64 (result i32)
        f64.const 5
        f64.const 14
        f64.ge
    )
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.lt_si %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_1() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.le_si %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_2() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.lt_ui %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_3() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.le_ui %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_4() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.gt_si %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_5() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.gt_ui %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_6() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.ge_si %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_7() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.ge_ui %[[VAL_0]] %[[VAL_1]] : i32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_8() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.lt_si %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_9() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.le_si %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_10() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.lt_ui %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_11() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.le_ui %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_12() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.gt_si %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_13() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.gt_ui %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_14() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.ge_si %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_15() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 12 : i64
// CHECK:           %[[VAL_1:.*]] = wasm.const 50 : i64
// CHECK:           %[[VAL_2:.*]] = wasm.ge_ui %[[VAL_0]] %[[VAL_1]] : i64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_16() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.lt %[[VAL_0]] %[[VAL_1]] : f32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_17() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.le %[[VAL_0]] %[[VAL_1]] : f32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_18() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.gt %[[VAL_0]] %[[VAL_1]] : f32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_19() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f32
// CHECK:           %[[VAL_2:.*]] = wasm.ge %[[VAL_0]] %[[VAL_1]] : f32 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_20() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.lt %[[VAL_0]] %[[VAL_1]] : f64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_21() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.le %[[VAL_0]] %[[VAL_1]] : f64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_22() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.gt %[[VAL_0]] %[[VAL_1]] : f64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32

// CHECK-LABEL:   wasm.func nested @func_23() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 5.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.const 1.400000e+01 : f64
// CHECK:           %[[VAL_2:.*]] = wasm.ge %[[VAL_0]] %[[VAL_1]] : f64 -> i32
// CHECK:           wasm.return %[[VAL_2]] : i32
