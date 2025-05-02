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

// CHECK-LABEL:   "wasm.func"() <{functionType = (i32, i32) -> i32, sym_name = "func_1", sym_visibility = "nested"}> ({
// CHECK:         }) : () -> ()
// CHECK:         "wasm.memory"() <{limits = !wasm<limit"[2:]">, sym_name = "mem_0"}> {sym_visibility = "nested"} : () -> ()

// CHECK-LABEL:   wasm.global @global_0 i32 mutable : {sym_visibility = "nested"} {
// CHECK:           %[[VAL_0:.*]] = wasm.empty_stack
// CHECK:           %[[VAL_1:.*]] = wasm.const 66560 : i32 on %[[VAL_0]]
// CHECK:           %[[VAL_2:.*]] = wasm.pop i32 from %[[VAL_1]]
// CHECK:         }

