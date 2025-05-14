// RUN: mlir-translate --import-wasm %S/inputs/local.wasm | FileCheck %s
/* Source code used to create this test:
(module
  (func $local_f32 (result f32)
    (local $var1 f32)
    (local $var2 f32)
    f32.const 8.0
    local.set $var1
    local.get $var1
    f32.const 12.0
    local.tee $var2
    f32.add
  )
  (func $local_i32 (result i32)
    (local $var1 i32)
    (local $var2 i32)
    i32.const 8
    local.set $var1
    local.get $var1
    i32.const 12
    local.tee $var2
    i32.add
  )
  (func $local_arg (param $var i32) (result i32)
    i32.const 3
    local.set $var
    local.get $var
  )
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> f32
// CHECK:           %[[VAL_0:.*]] = wasm.local f32
// CHECK:           %[[VAL_1:.*]] = wasm.local f32
// CHECK:           %[[VAL_2:.*]] = wasm.const 8.000000e+00 : f32
// CHECK:           %[[VAL_3:.*]] = wasm.const 1.200000e+01 : f32
// CHECK:           %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : f32
// CHECK:           wasm.return %[[VAL_4]] : f32

// CHECK-LABEL:   wasm.func nested @func_1() -> i32
// CHECK:           %[[VAL_0:.*]] = wasm.local i32
// CHECK:           %[[VAL_1:.*]] = wasm.local i32
// CHECK:           %[[VAL_2:.*]] = wasm.const 8 : i32
// CHECK:           %[[VAL_3:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : i32
// CHECK:           wasm.return %[[VAL_4]] : i32

// CHECK-LABEL:   wasm.func nested @func_2(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 3 : i32
// CHECK:           wasm.return %[[VAL_1]] : i32
