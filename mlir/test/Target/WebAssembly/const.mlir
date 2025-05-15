// RUN: mlir-translate --import-wasm %S/inputs/const.wasm | FileCheck %s

/* Source code used to create this test:
(module
(func(result i32)
i32.const 0
)
)
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 0 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
