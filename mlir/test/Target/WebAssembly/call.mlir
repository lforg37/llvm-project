// RUN: mlir-translate --import-wasm %S/inputs/call.wasm | FileCheck %s

/* Source code used to create this test:
(module
(func $forty_two (result i32)
i32.const 42)
(func(export "forty_two")(result i32)
call $forty_two))
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 42 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_1() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.call @func_0 : () -> i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }
// CHECK:         wasm.export @func_1 as @forty_two
