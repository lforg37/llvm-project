// RUN: yaml2obj %S/inputs/loop.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s

/* IR generated from:
(module
  (func
    (loop $my_loop
    )
  )
)*/

// CHECK-LABEL:   wasm.func nested @func_0() {
// CHECK:           wasm.loop : {
// CHECK:             wasm.block_return
// CHECK:           }> ^bb1
// CHECK:         ^bb1:
// CHECK:           wasm.return
// CHECK:         }
