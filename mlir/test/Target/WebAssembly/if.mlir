// RUN: mlir-translate --import-wasm %S/inputs/if.wasm | FileCheck %s

/* Source code used to create this test:
(module
(type $intMapper (func (param $input i32) (result i32)))
(func $if_else (type $intMapper)
  local.get 0
  i32.const 1
  i32.and
  if $isOdd (result i32)
    local.get 0
    i32.const 3
    i32.mul
    i32.const 1
    i32.add
  else
    local.get 0
    i32.const 1
    i32.shr_u
  end
)

(func $if_only (type $intMapper)
  local.get 0
  local.get 0
  i32.const 1
  i32.and
  if $isOdd (type $intMapper)
    i32.const 1
    i32.add
  end
)

(func $if_if (type $intMapper)
  local.get 0
  i32.ctz
  if $isEven (result i32)
    i32.const 2
    local.get 0
    i32.const 1
    i32.shr_u
    i32.ctz
    if $isMultipleOfFour (type $intMapper)
      i32.const 2
      i32.add
    end
  else
    i32.const 1
  end
)
)
*/

// CHECK-LABEL:   wasm.func nested @func_0(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           %[[VAL_2:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = wasm.const 1 : i32
// CHECK:           %[[VAL_4:.*]] = wasm.and %[[VAL_2]] %[[VAL_3]] : i32
// CHECK:           "wasm.if"(%[[VAL_4]])[^bb1] ({
// CHECK:             %[[VAL_5:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:             %[[VAL_6:.*]] = wasm.const 3 : i32
// CHECK:             %[[VAL_7:.*]] = wasm.mul %[[VAL_5]] %[[VAL_6]] : i32
// CHECK:             %[[VAL_8:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_9:.*]] = wasm.add %[[VAL_7]] %[[VAL_8]] : i32
// CHECK:             wasm.block_return %[[VAL_9]] : i32
// CHECK:           }, {
// CHECK:             %[[VAL_10:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:             %[[VAL_11:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_12:.*]] = wasm.shr_u %[[VAL_10]] by %[[VAL_11]] bits : i32
// CHECK:             wasm.block_return %[[VAL_12]] : i32
// CHECK:           }) : (i32) -> ()
// CHECK:         ^bb1(%[[VAL_13:.*]]: i32):
// CHECK:           wasm.return %[[VAL_13]] : i32

// CHECK-LABEL:   wasm.func nested @func_1(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           %[[VAL_2:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:           %[[VAL_4:.*]] = wasm.const 1 : i32
// CHECK:           %[[VAL_5:.*]] = wasm.and %[[VAL_3]] %[[VAL_4]] : i32
// CHECK:           "wasm.if"(%[[VAL_5]], %[[VAL_2]])[^bb1] ({
// CHECK:           ^bb0(%[[VAL_6:.*]]: i32):
// CHECK:             %[[VAL_7:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_8:.*]] = wasm.add %[[VAL_6]] %[[VAL_7]] : i32
// CHECK:             wasm.block_return %[[VAL_8]] : i32
// CHECK:           }, {
// CHECK:           }) : (i32, i32) -> ()
// CHECK:         ^bb1(%[[VAL_9:.*]]: i32):
// CHECK:           wasm.return %[[VAL_9]] : i32

// CHECK-LABEL:   wasm.func nested @func_2(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = wasm.local_from_arg %[[VAL_0]] : i32
// CHECK:           %[[VAL_2:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = wasm.ctz %[[VAL_2]] : i32
// CHECK:           "wasm.if"(%[[VAL_3]])[^bb1] ({
// CHECK:             %[[VAL_4:.*]] = wasm.const 2 : i32
// CHECK:             %[[VAL_5:.*]] = wasm.local_get %[[VAL_1]] : memref<i32>
// CHECK:             %[[VAL_6:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_7:.*]] = wasm.shr_u %[[VAL_5]] by %[[VAL_6]] bits : i32
// CHECK:             %[[VAL_8:.*]] = wasm.ctz %[[VAL_7]] : i32
// CHECK:             "wasm.if"(%[[VAL_8]], %[[VAL_4]])[^bb1] ({
// CHECK:             ^bb0(%[[VAL_9:.*]]: i32):
// CHECK:               %[[VAL_10:.*]] = wasm.const 2 : i32
// CHECK:               %[[VAL_11:.*]] = wasm.add %[[VAL_9]] %[[VAL_10]] : i32
// CHECK:               wasm.block_return %[[VAL_11]] : i32
// CHECK:             }, {
// CHECK:             }) : (i32, i32) -> ()
// CHECK:           ^bb1(%[[VAL_12:.*]]: i32):
// CHECK:             wasm.block_return %[[VAL_12]] : i32
// CHECK:           }, {
// CHECK:             %[[VAL_13:.*]] = wasm.const 1 : i32
// CHECK:             wasm.block_return %[[VAL_13]] : i32
// CHECK:           }) : (i32) -> ()
// CHECK:         ^bb1(%[[VAL_14:.*]]: i32):
// CHECK:           wasm.return %[[VAL_14]] : i32
