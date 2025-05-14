// XFAIL: *
// RUN: mlir-translate --import-wasm %S/inputs/load.wasm | FileCheck %s

/* Source code used to create this test:
(module
(memory (import "js" "mem")1)
(func(export "load_from_mem")(param $ptr i32)(param $len i32)(result i32)
(local $x i32)
(local.set $x (i32.load (local.get $ptr)))
(local.get 0)
)
)
*/
