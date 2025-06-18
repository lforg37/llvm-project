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
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i32>) {
// CHECK:           wasm.block : {
// CHECK:             wasm.block : {
// CHECK:               wasm.block : {
// CHECK:                 wasm.block_return
// CHECK:               }> ^bb1
// CHECK:             ^bb1:
// CHECK:               wasm.block_return
// CHECK:             }> ^bb1
// CHECK:           ^bb1:
// CHECK:             wasm.block_return
// CHECK:           }> ^bb1
// CHECK:         ^bb1:
// CHECK:           wasm.return

// CHECK-LABEL:   wasm.func nested @func_1(
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i32>) {
// CHECK:           wasm.block : {
// CHECK:             wasm.block_return
// CHECK:           }> ^bb1
// CHECK:         ^bb1:
// CHECK:           wasm.block : {
// CHECK:             wasm.block_return
// CHECK:           }> ^bb2
// CHECK:         ^bb2:
// CHECK:           wasm.block : {
// CHECK:             wasm.block_return
// CHECK:           }> ^bb3
// CHECK:         ^bb3:
// CHECK:           wasm.return
