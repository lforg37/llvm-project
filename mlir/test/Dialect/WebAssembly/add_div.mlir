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

// CHECK: module {
// CHECK-NEXT:   "wasm.global"() <{isMutable, sym_name = "global_0", type = i32}> ({
// CHECK-NEXT:     %[[STACK:.*]] = wasm.empty_stack
// CHECK-NEXT:     %[[CST_0:.*]] = wasm.const 66560 : i32 on %[[STACK]]
// CHECK-NEXT:     %[[POP:.*]] = wasm.pop i32 from %[[CST_0]]
// CHECK-NEXT:   }) {sym_visibility = "nested"} : () -> ()
// CHECK-NEXT: }

