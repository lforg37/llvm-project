// RUN: mlir-translate --import-wasm %S/inputs/empty_blocks_list_and_stack.wasm | FileCheck %s

/* Source code used to create this test:
(module
  (func (param $num i32)
    (block $b1
        (block $b2
            (block $b3
            )
        )
    )
  )

  (func (param $num i32)
    (block $b1)
    (block $b2)
    (block $b3)
  )
)

*/

// CHECK-LABEL:   wasm.func nested @func_0(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) {
// CHECK:           %[[VAL_1:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           wasm.block : () -> () {
// CHECK:             wasm.block : () -> () {
// CHECK:               wasm.block : () -> () {
// CHECK:                 wasm.return
// CHECK:               }
// CHECK:               wasm.return
// CHECK:             }
// CHECK:             wasm.return
// CHECK:           }
// CHECK:           wasm.return
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_1(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) {
// CHECK:           %[[VAL_1:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           wasm.block : () -> () {
// CHECK:             wasm.return
// CHECK:           }
// CHECK:           wasm.block : () -> () {
// CHECK:             wasm.return
// CHECK:           }
// CHECK:           wasm.block : () -> () {
// CHECK:             wasm.return
// CHECK:           }
// CHECK:           wasm.return
// CHECK:         }
