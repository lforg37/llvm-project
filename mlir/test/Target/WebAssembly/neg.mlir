// RUN: mlir-translate --import-wasm %S/inputs/neg.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "neg_f32") (result f32)
    f32.const 10
    f32.neg)

    (func (export "neg_f64") (result f64)
    f64.const 10
    f64.neg)
)
*/

// CHECK-LABEL:   wasm.func @neg_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.neg %[[VAL_0]] : f32
// CHECK:           wasm.return %[[VAL_1]] : f32

// CHECK-LABEL:   wasm.func @neg_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.000000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.neg %[[VAL_0]] : f64
// CHECK:           wasm.return %[[VAL_1]] : f64
