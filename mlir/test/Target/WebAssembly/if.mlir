// RUN: yaml2obj %S/inputs/if.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s

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
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:           %[[VAL_1:.*]] = wasm.const 1 : i32
// CHECK:           %[[VAL_2:.*]] = wasm.and %[[VAL_0]] %[[VAL_1]] : i32
// CHECK:           "wasm.if"(%[[VAL_2]])[^bb1] ({
// CHECK:             %[[VAL_3:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:             %[[VAL_4:.*]] = wasm.const 3 : i32
// CHECK:             %[[VAL_5:.*]] = wasm.mul %[[VAL_3]] %[[VAL_4]] : i32
// CHECK:             %[[VAL_6:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_7:.*]] = wasm.add %[[VAL_5]] %[[VAL_6]] : i32
// CHECK:             wasm.block_return %[[VAL_7]] : i32
// CHECK:           }, {
// CHECK:             %[[VAL_8:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:             %[[VAL_9:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_10:.*]] = wasm.shr_u %[[VAL_8]] by %[[VAL_9]] bits : i32
// CHECK:             wasm.block_return %[[VAL_10]] : i32
// CHECK:           }) : (i32) -> ()
// CHECK:         ^bb1(%[[VAL_11:.*]]: i32):
// CHECK:           wasm.return %[[VAL_11]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_1(
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:           %[[VAL_1:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:           %[[VAL_2:.*]] = wasm.const 1 : i32
// CHECK:           %[[VAL_3:.*]] = wasm.and %[[VAL_1]] %[[VAL_2]] : i32
// CHECK:           "wasm.if"(%[[VAL_3]], %[[VAL_0]])[^bb1] ({
// CHECK:           ^bb0(%[[VAL_4:.*]]: i32):
// CHECK:             %[[VAL_5:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_6:.*]] = wasm.add %[[VAL_4]] %[[VAL_5]] : i32
// CHECK:             wasm.block_return %[[VAL_6]] : i32
// CHECK:           }, {
// CHECK:           }) : (i32, i32) -> ()
// CHECK:         ^bb1(%[[VAL_7:.*]]: i32):
// CHECK:           wasm.return %[[VAL_7]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_2(
// CHECK-SAME:      %[[ARG0:.*]]: !wasm<local ref to i32>) -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:           %[[VAL_1:.*]] = wasm.ctz %[[VAL_0]] : i32
// CHECK:           "wasm.if"(%[[VAL_1]])[^bb1] ({
// CHECK:             %[[VAL_2:.*]] = wasm.const 2 : i32
// CHECK:             %[[VAL_3:.*]] = wasm.local_get %[[ARG0]] :  ref to i32
// CHECK:             %[[VAL_4:.*]] = wasm.const 1 : i32
// CHECK:             %[[VAL_5:.*]] = wasm.shr_u %[[VAL_3]] by %[[VAL_4]] bits : i32
// CHECK:             %[[VAL_6:.*]] = wasm.ctz %[[VAL_5]] : i32
// CHECK:             "wasm.if"(%[[VAL_6]], %[[VAL_2]])[^bb1] ({
// CHECK:             ^bb0(%[[VAL_7:.*]]: i32):
// CHECK:               %[[VAL_8:.*]] = wasm.const 2 : i32
// CHECK:               %[[VAL_9:.*]] = wasm.add %[[VAL_7]] %[[VAL_8]] : i32
// CHECK:               wasm.block_return %[[VAL_9]] : i32
// CHECK:             }, {
// CHECK:             }) : (i32, i32) -> ()
// CHECK:           ^bb1(%[[VAL_10:.*]]: i32):
// CHECK:             wasm.block_return %[[VAL_10]] : i32
// CHECK:           }, {
// CHECK:             %[[VAL_11:.*]] = wasm.const 1 : i32
// CHECK:             wasm.block_return %[[VAL_11]] : i32
// CHECK:           }) : (i32) -> ()
// CHECK:         ^bb1(%[[VAL_12:.*]]: i32):
// CHECK:           wasm.return %[[VAL_12]] : i32
// CHECK:         }
