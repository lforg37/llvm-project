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
  (global $__stack_pointer (mut i32) (i32.const 66560))
  (export "add" (func $add)))

