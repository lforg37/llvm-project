// RUN: mlir-translate --import-wasm %S/inputs/nearest.wasm | FileCheck %s

/* Source code used to generate this test:
(module
    (func (export "nearest_f32") (result f32)
    f32.const -1.0
    f32.nearest)

    (func (export "nearest_f64") (result f64)
    f64.const -1.0
    f64.nearest)
)
*/

// CHECK-LABEL:   wasm.func @nearest_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.000000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.nearest %[[VAL_0]] : f32
// CHECK:           wasm.return %[[VAL_1]] : f32

// CHECK-LABEL:   wasm.func @nearest_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.000000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.nearest %[[VAL_0]] : f64
// CHECK:           wasm.return %[[VAL_1]] : f64
