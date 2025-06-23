// RUN: mlir-translate --import-wasm %S/inputs/demote.wasm | FileCheck %s
/* Source code used to create this test:
(module
  (func $main (result f32)
    f64.const 2.24
    f32.demote_f64
    )
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 2.240000e+00 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.demote %[[VAL_0]] : f64 to f32
// CHECK:           wasm.return %[[VAL_1]] : f32
