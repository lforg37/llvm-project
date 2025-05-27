// RUN: mlir-translate --import-wasm %S/inputs/add_div.wasm | FileCheck %s

/* Source code used to create this test:
 (module $test.wasm
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (import "env" "twoTimes" (func $twoTimes (type 0)))
  (func $add (type 1) (param i32 i32) (result i32)
    local.get 0
    call $twoTimes
    local.get 1
    call $twoTimes
    i32.add
    i32.const 2
    i32.div_s)
  (memory (;0;) 2)
  (global $__stack_pointer (mut i32) (i32.const 66560))
  (export "memory" (memory 0))
  (export "add" (func $add)))
*/

// CHECK-LABEL:   wasm.import_func "twoTimes" from "env" as @func_0 {sym_visibility = "nested", type = (i32) -> i32}

// CHECK-LABEL:   wasm.func @add(
// CHECK-SAME:                   %[[VAL_0:.*]]: i32,
// CHECK-SAME:                   %[[VAL_1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_2:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           %[[VAL_3:.*]] = wasm.local_from_arg %[[VAL_1]] : i32
// CHECK:           %[[VAL_4:.*]] = wasm.local_get %[[VAL_2]] : memref<i32>
// CHECK:           %[[VAL_5:.*]] = wasm.call @func_0(%[[VAL_4]]) : (i32) -> i32
// CHECK:           %[[VAL_6:.*]] = wasm.local_get %[[VAL_3]] : memref<i32>
// CHECK:           %[[VAL_7:.*]] = wasm.call @func_0(%[[VAL_6]]) : (i32) -> i32
// CHECK:           %[[VAL_8:.*]] = wasm.add %[[VAL_5]] %[[VAL_7]] : i32
// CHECK:           %[[VAL_9:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_10:.*]] = wasm.div_si %[[VAL_8]] %[[VAL_9]] : i32
// CHECK:           wasm.return %[[VAL_10]] : i32
// CHECK:         }
// CHECK:         "wasm.memory"() <{limits = !wasm<limit[2:]>, sym_name = "memory"}> : () -> ()

// CHECK-LABEL:   wasm.global @global_0 i32 mutable : {
// CHECK:           %[[VAL_0:.*]] = wasm.const 66560 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
