// RUN: mlir-translate --import-wasm %S/inputs/block_complete_type.wasm | FileCheck %s

/* Source code used to create this test:
(module
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (result i32)))
  (func (;0;) (type 1) (result i32)
    i32.const 14
    block (param i32) (result i32)  ;; label = @1
      i32.const 1
      i32.add
    end))
*/

// CHECK-LABEL:   wasm.func nested @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.const 14 : i32
// CHECK:           %[[VAL_1:.*]] = wasm.block(%[[VAL_0]]) : (i32) -> i32 {
// CHECK:           ^bb0(%[[VAL_2:.*]]: i32):
// CHECK:             %[[VAL_3:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : i32
// CHECK:             wasm.return %[[VAL_4]] : i32
// CHECK:           }
// CHECK:           wasm.return %[[VAL_1]] : i32
// CHECK:         }
