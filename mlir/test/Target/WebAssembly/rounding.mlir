// RUN: yaml2obj %S/inputs/rounding.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s
/* Source code used to create this test:
(module
  (func $ceil_f64 (result f64)
    f64.const -12.1
    f64.ceil
  )
  (func $ceil_f32 (result f32)
    f32.const 1.618
    f32.ceil
  )
  (func $floor_f64 (result f64)
    f64.const -12.1
    f64.floor
  )
  (func $floor_f32 (result f32)
    f32.const 1.618
    f32.floor
  )
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.210000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.ceil %[[VAL_0]] : f64
// CHECK:           wasm.return %[[VAL_1]] : f64

// CHECK-LABEL:   wasm.func nested @func_1() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.618000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.ceil %[[VAL_0]] : f32
// CHECK:           wasm.return %[[VAL_1]] : f32

// CHECK-LABEL:   wasm.func nested @func_2() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.210000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.floor %[[VAL_0]] : f64
// CHECK:           wasm.return %[[VAL_1]] : f64

// CHECK-LABEL:   wasm.func nested @func_3() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.618000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.floor %[[VAL_0]] : f32
// CHECK:           wasm.return %[[VAL_1]] : f32

// CHECK-LABEL:   wasm.func nested @func_4() -> f64 {
// CHECK:           %[[VAL_0:.*]] = wasm.const -1.210000e+01 : f64
// CHECK:           %[[VAL_1:.*]] = wasm.trunc %[[VAL_0]] : f64
// CHECK:           wasm.return %[[VAL_1]] : f64

// CHECK-LABEL:   wasm.func nested @func_5() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 1.618000e+00 : f32
// CHECK:           %[[VAL_1:.*]] = wasm.trunc %[[VAL_0]] : f32
// CHECK:           wasm.return %[[VAL_1]] : f32
