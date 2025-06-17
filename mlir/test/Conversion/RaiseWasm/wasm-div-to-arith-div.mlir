// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s

// CHECK-LABEL:   func.func @div_i32_si(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32,
// CHECK-SAME:                      %[[VAL_1:.*]]: i32) -> i32 {
wasm.func nested @div_i32_si(%arg0: i32, %arg1: i32) -> i32 {

// CHECK:           %[[VAL_2:.*]] = arith.divsi %[[VAL_0]], %[[VAL_1]] : i32
%0 = wasm.div_si %arg0 %arg1 : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.return %0 : i32
}


// CHECK-LABEL:   func.func @div_i32_ui(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32,
// CHECK-SAME:                      %[[VAL_1:.*]]: i32) -> i32 {
wasm.func nested @div_i32_ui(%arg0: i32, %arg1: i32) -> i32 {

// CHECK:           %[[VAL_2:.*]] = arith.divui %[[VAL_0]], %[[VAL_1]] : i32
%0 = wasm.div_ui %arg0 %arg1 : i32
// CHECK:           return %[[VAL_2]] : i32
wasm.return %0 : i32
}

// CHECK-LABEL:   func.func @div_i64_si(
// CHECK-SAME:                      %[[VAL_0:.*]]: i64,
// CHECK-SAME:                      %[[VAL_1:.*]]: i64) -> i64 {
wasm.func nested @div_i64_si(%arg0: i64, %arg1: i64) -> i64 {

// CHECK:           %[[VAL_2:.*]] = arith.divsi %[[VAL_0]], %[[VAL_1]] : i64
%0 = wasm.div_si %arg0 %arg1 : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.return %0 : i64
}


// CHECK-LABEL:   func.func @div_i64_ui(
// CHECK-SAME:                      %[[VAL_0:.*]]: i64,
// CHECK-SAME:                      %[[VAL_1:.*]]: i64) -> i64 {
wasm.func nested @div_i64_ui(%arg0: i64, %arg1: i64) -> i64 {

// CHECK:           %[[VAL_2:.*]] = arith.divui %[[VAL_0]], %[[VAL_1]] : i64
%0 = wasm.div_ui %arg0 %arg1 : i64
// CHECK:           return %[[VAL_2]] : i64
wasm.return %0 : i64
}


// CHECK-LABEL:   func.func @div_f32(
// CHECK-SAME:                      %[[VAL_0:.*]]: f32,
// CHECK-SAME:                      %[[VAL_1:.*]]: f32) -> f32 {
wasm.func nested @div_f32(%arg0: f32, %arg1: f32) -> f32 {

// CHECK:           %[[VAL_2:.*]] = arith.divf %[[VAL_0]], %[[VAL_1]] : f32
%0 = wasm.div %arg0 %arg1 : f32
// CHECK:           return %[[VAL_2]] : f32
wasm.return %0 : f32
}

// CHECK-LABEL:   func.func @div_f64(
// CHECK-SAME:                      %[[VAL_0:.*]]: f64,
// CHECK-SAME:                      %[[VAL_1:.*]]: f64) -> f64 {
wasm.func nested @div_f64(%arg0: f64, %arg1: f64) -> f64 {

// CHECK:           %[[VAL_2:.*]] = arith.divf %[[VAL_0]], %[[VAL_1]] : f64
%0 = wasm.div %arg0 %arg1 : f64
// CHECK:           return %[[VAL_2]] : f64
wasm.return %0 : f64
}
