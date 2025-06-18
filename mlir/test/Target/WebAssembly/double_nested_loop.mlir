// RUN: mlir-translate --import-wasm %S/inputs/double_nest_loop.wasm | FileCheck %s

/*
(module
  (func
    ;; create a local variable and initialize it to 0
    (local $i i32)
    (local $j i32)

    (loop $my_loop

      ;; add one to $i
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      (loop $my_second_loop (result i32)
        i32.const 1
        local.get $j
        i32.const 12
        i32.add
        local.tee $j
        local.get $i
        i32.gt_s
        br_if $my_second_loop
      )
      i32.const 10
      i32.lt_s
      br_if $my_loop
    )
  )
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() {
// CHECK:           %[[VAL_0:.*]] = wasm.local of type i32
// CHECK:           %[[VAL_1:.*]] = wasm.local of type i32
// CHECK:           wasm.loop : {
// CHECK:             %[[VAL_2:.*]] = wasm.local_get %[[VAL_0]] :  ref to i32
// CHECK:             %[[VAL_3:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : i32
// CHECK:             wasm.local_set %[[VAL_0]] :  ref to i32 to %[[VAL_4]] : i32
// CHECK:             wasm.loop : {
// CHECK:               %[[VAL_5:.*]] = wasm.const 1 : i32
// CHECK:               %[[VAL_6:.*]] = wasm.local_get %[[VAL_1]] :  ref to i32
// CHECK:               %[[VAL_7:.*]] = wasm.const 12 : i32
// CHECK:               %[[VAL_8:.*]] = wasm.add %[[VAL_6]] %[[VAL_7]] : i32
// CHECK:               %[[VAL_9:.*]] = wasm.local_tee %[[VAL_1]] :  ref to i32 to %[[VAL_8]] : i32
// CHECK:               %[[VAL_10:.*]] = wasm.local_get %[[VAL_0]] :  ref to i32
// CHECK:               %[[VAL_11:.*]] = wasm.gt_si %[[VAL_9]] %[[VAL_10]] : i32 -> i32
// CHECK:               wasm.branch_if %[[VAL_11]] to level 0 else ^bb1
// CHECK:             ^bb1:
// CHECK:               wasm.block_return %[[VAL_5]] : i32
// CHECK:             }> ^bb1
// CHECK:           ^bb1(%[[VAL_12:.*]]: i32):
// CHECK:             %[[VAL_13:.*]] = wasm.const 10 : i32
// CHECK:             %[[VAL_14:.*]] = wasm.lt_si %[[VAL_12]] %[[VAL_13]] : i32 -> i32
// CHECK:             wasm.branch_if %[[VAL_14]] to level 0 else ^bb2
// CHECK:           ^bb2:
// CHECK:             wasm.block_return
// CHECK:           }> ^bb1
// CHECK:         ^bb1:
// CHECK:           wasm.return
