// RUN: mlir-translate --import-wasm %S/inputs/loop_with_inst.wasm | FileCheck %s

/* Code used to create this test:

(module
  (func (result i32)
    (local $i i32)
    (loop $my_loop (result i32)
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      local.get $i
      i32.const 10
      i32.lt_s
    )
  )
)*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local i32
// CHECK:           wasm.loop : {
// CHECK:             %[[VAL_1:.*]] = wasm.local_get %[[VAL_0]] : memref<i32>
// CHECK:             %[[VAL_2:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_3:.*]] = wasm.add %[[VAL_1]] %[[VAL_2]] : i32
// CHECK:             wasm.local_set %[[VAL_0]] : memref<i32> to %[[VAL_3]] : i32
// CHECK:             %[[VAL_4:.*]] = wasm.local_get %[[VAL_0]] : memref<i32>
// CHECK:             %[[VAL_5:.*]] = wasm.const 10 : i32
// CHECK:             %[[VAL_6:.*]] = wasm.lt_si %[[VAL_4]] %[[VAL_5]] : i32 -> i32
// CHECK:             wasm.block_return %[[VAL_6]] : i32
// CHECK:           }> ^bb1
// CHECK:         ^bb1(%[[VAL_7:.*]]: i32):
// CHECK:           wasm.return %[[VAL_7]] : i32
