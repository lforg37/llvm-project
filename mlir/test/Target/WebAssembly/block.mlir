// RUN: mlir-translate --import-wasm %S/inputs/block.wasm | FileCheck %s

/* Source code used to create this test:
(module
(func(export "i_am_a_block")
(block $i_am_a_block)
)
)
*/

// CHECK-LABEL:   wasm.func @i_am_a_block() {
// CHECK:           wasm.block : () -> () {
// CHECK:             wasm.return
// CHECK:           }
// CHECK:           wasm.return
