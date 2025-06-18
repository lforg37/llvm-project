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
// CHECK-SAME:                   %[[ARG0:.*]]: !wasm<local ref to i32>,
// CHECK-SAME:                   %[[ARG1:.*]]: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:           %[[VAL_1:.*]] = wasm.call @func_0(%[[VAL_0]]) : (i32) -> i32
// CHECK:           %[[VAL_2:.*]] = wasm.local_get %[[ARG1]] :  ref to i32
// CHECK:           %[[VAL_3:.*]] = wasm.call @func_0(%[[VAL_2]]) : (i32) -> i32
// CHECK:           %[[VAL_4:.*]] = wasm.add %[[VAL_1]] %[[VAL_3]] : i32
// CHECK:           %[[VAL_5:.*]] = wasm.const 2 : i32
// CHECK:           %[[VAL_6:.*]] = wasm.div_si %[[VAL_4]] %[[VAL_5]] : i32
// CHECK:           wasm.return %[[VAL_6]] : i32
// CHECK:         }
// CHECK:         "wasm.memory"() <{limits = !wasm<limit[2:]>, sym_name = "memory"}> : () -> ()

// CHECK-LABEL:   wasm.global @global_0 i32 mutable nested : {
// CHECK:           %[[VAL_0:.*]] = wasm.const 66560 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
