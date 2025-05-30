// RUN: mlir-opt --split-input-file %s --convert-wasm-to-standard -o - | FileCheck %s
// RUN: mlir-opt --split-input-file %s --convert-wasm-to-standard --canonicalize -o - | FileCheck --check-prefix=CANONICALIZED_CHECK %s

// CHECK-LABEL:   func.func @i_am_a_block(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[VAL_0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = arith.constant 17 : i32
// CHECK:           memref.store %[[VAL_2]], %[[VAL_1]][] : memref<i32>
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_3:.*]] = arith.constant 42 : i32
// CHECK:           memref.store %[[VAL_3]], %[[VAL_1]][] : memref<i32>
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_4:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           return %[[VAL_4]] : i32

// CANONICALIZED_CHECK-LABEL:   func.func @i_am_a_block(
// CANONICALIZED_CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CANONICALIZED_CHECK:           %[[VAL_1:.*]] = arith.constant 42 : i32
// CANONICALIZED_CHECK:           %[[VAL_3:.*]] = memref.alloca() : memref<i32>
// CANONICALIZED_CHECK:           memref.store %[[VAL_1]], %[[VAL_3]][] : memref<i32>
// CANONICALIZED_CHECK-NOT:       memref.store
// CANONICALIZED_CHECK:           %[[VAL_4:.*]] = memref.load %[[VAL_3]][] : memref<i32>
// CANONICALIZED_CHECK:           return %[[VAL_4]] : i32
wasm.func @i_am_a_block(%arg0 : i32) -> i32 {
  %0 = wasm.local_from_arg %arg0 : i32
  %1 = wasm.const 17 : i32
  wasm.local_set %0 : memref<i32> to %1 : i32
  wasm.block : {
    %2 = wasm.const 42 : i32
    wasm.local_set %0 : memref<i32> to %2 : i32
    wasm.block_return
  }> ^bb1
  ^bb1:
  %res = wasm.local_get %0 : memref<i32>
  wasm.return %res : i32
}


// CHECK-LABEL:   func.func @func_0(
// CHECK-SAME:                      %[[VAL_0:.*]]: i32) {
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[VAL_0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = arith.constant 1 : i32
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_3:.*]] = arith.constant 2 : i32
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_4:.*]] = arith.constant 3 : i32
// CHECK:           cf.br ^bb3
// CHECK:         ^bb3:
// CHECK:           %[[VAL_5:.*]] = arith.constant 4 : i32
// CHECK:           cf.br ^bb4
// CHECK:         ^bb4:
// CHECK:           %[[VAL_6:.*]] = arith.constant 5 : i32
// CHECK:           cf.br ^bb5
// CHECK:         ^bb5:
// CHECK:           %[[VAL_7:.*]] = arith.constant 6 : i32
// CHECK:           cf.br ^bb6
// CHECK:         ^bb6:
// CHECK:           %[[VAL_8:.*]] = arith.constant 7 : i32
// CHECK:           return
wasm.func nested @func_0(%arg0: i32) {
  %0 = wasm.local_from_arg %arg0 : i32
  %1 = wasm.const 1: i32
  wasm.block : {
    %2 = wasm.const 2: i32
    wasm.block : {
      %3 = wasm.const 3: i32
      wasm.block : {
        %4 = wasm.const 4: i32
        wasm.block_return
      }> ^bb1
    ^bb1:  // pred: ^bb0
      %5 = wasm.const 5: i32
      wasm.block_return
    }> ^bb1
  ^bb1:  // pred: ^bb0
    %6 = wasm.const 6: i32
    wasm.block_return
  }> ^bb1
^bb1:  // pred: ^bb0
  %7 = wasm.const 7: i32
  wasm.return
}

// CHECK-LABEL:   func.func @func_1() {
// CHECK:           %[[VAL_0:.*]] = arith.constant 1 : i32
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_1:.*]] = arith.constant 2 : i32
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_2:.*]] = arith.constant 3 : i32
// CHECK:           cf.br ^bb3
// CHECK:         ^bb3:
// CHECK:           %[[VAL_3:.*]] = arith.constant 4 : i32
// CHECK:           cf.br ^bb4
// CHECK:         ^bb4:
// CHECK:           %[[VAL_4:.*]] = arith.constant 5 : i32
// CHECK:           cf.br ^bb5
// CHECK:         ^bb5:
// CHECK:           %[[VAL_5:.*]] = arith.constant 6 : i32
// CHECK:           cf.br ^bb6
// CHECK:         ^bb6:
// CHECK:           %[[VAL_6:.*]] = arith.constant 7 : i32
// CHECK:           return
wasm.func nested @func_1() {
  %1 = wasm.const 1: i32
  wasm.block : {
    %2 = wasm.const 2: i32
    wasm.block_return
  }> ^bb1
^bb1:  // pred: ^bb0
  %3 = wasm.const 3: i32
  wasm.block : {
    %4 = wasm.const 4: i32
    wasm.block_return
  }> ^bb2
^bb2:  // pred: ^bb1
  %5 = wasm.const 5: i32
  wasm.block : {
    %6 = wasm.const 6: i32
    wasm.block_return
  }> ^bb3
^bb3:  // pred: ^bb2
  %7 = wasm.const 7: i32
  wasm.return
}

// CHECK-LABEL:   func.func @func_2() -> i32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 14 : i32
// CHECK:           cf.br ^bb1(%[[VAL_0]] : i32)
// CHECK:         ^bb1(%[[VAL_1:.*]]: i32):
// CHECK:           %[[VAL_2:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_3:.*]] = arith.addi %[[VAL_1]], %[[VAL_2]] : i32
// CHECK:           cf.br ^bb2(%[[VAL_3]] : i32)
// CHECK:         ^bb2(%[[VAL_4:.*]]: i32):
// CHECK:           return %[[VAL_4]] : i32
wasm.func nested @func_2() -> i32 {
  %0 = wasm.const 14 : i32
  wasm.block(%0) : i32 : {
  ^bb0(%arg0: i32):
    %2 = wasm.const 1 : i32
    %3 = wasm.add %arg0 %2 : i32
    wasm.block_return %3 : i32
  }> ^bb1
^bb1(%arg0: i32):
  wasm.return %arg0 : i32
}

// CHECK-LABEL:   func.func @func_3() -> i32 {
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_0:.*]] = arith.constant 17 : i32
// CHECK:           cf.br ^bb2(%[[VAL_0]] : i32)
// CHECK:         ^bb2(%[[VAL_1:.*]]: i32):
// CHECK:           return %[[VAL_1]] : i32
wasm.func nested @func_3() -> i32 {
  wasm.block : {
    %1 = wasm.const 17 : i32
    wasm.block_return %1 : i32
  }> ^bb1
^bb1(%arg0: i32):
  wasm.return %arg0 : i32
}
