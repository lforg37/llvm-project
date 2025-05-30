// RUN: mlir-opt --split-input-file %s --convert-wasm-to-standard -o - | FileCheck %s

// CHECK-LABEL:   func.func @neg_f32(
// CHECK-SAME:      %[[VAL_0:.*]]: f32) -> f32 {
// CHECK:           %[[VAL_1:.*]] = arith.negf %[[VAL_0]] : f32
// CHECK:           return %[[VAL_1]] : f32
// CHECK:         }
wasm.func nested @neg_f32(%arg0: f32) -> f32 {
    %op = wasm.neg %arg0 : f32
    wasm.return %op : f32
}

// CHECK-LABEL:   func.func @neg_f64(
// CHECK-SAME:      %[[VAL_0:.*]]: f64) -> f64 {
// CHECK:           %[[VAL_1:.*]] = arith.negf %[[VAL_0]] : f64
// CHECK:           return %[[VAL_1]] : f64
// CHECK:         }
wasm.func nested @neg_f64(%arg0: f64) -> f64 {
    %op = wasm.neg %arg0 : f64
    wasm.return %op : f64
}
