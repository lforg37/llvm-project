// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s
// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir --canonicalize -o - | FileCheck --check-prefix=CHECK_CANONICALIZED %s

// CHECK-LABEL:   func.func @i_am_a_block(
// CHECK-SAME:      %[[ARG0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = arith.constant 17 : i32
// CHECK:           memref.store %[[VAL_1]], %[[VAL_0]][] : memref<i32>
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_2:.*]] = arith.constant 42 : i32
// CHECK:           memref.store %[[VAL_2]], %[[VAL_0]][] : memref<i32>
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           return %[[VAL_3]] : i32

// CHECK_CANONICALIZED-LABEL:   func.func @i_am_a_block(
// CHECK_CANONICALIZED-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK_CANONICALIZED:           %[[VAL_1:.*]] = arith.constant 42 : i32
// CHECK_CANONICALIZED:           %[[VAL_3:.*]] = memref.alloca() : memref<i32>
// CHECK_CANONICALIZED:           memref.store %[[VAL_1]], %[[VAL_3]][] : memref<i32>
// CHECK_CANONICALIZED-NOT:       memref.store
// CHECK_CANONICALIZED:           %[[VAL_4:.*]] = memref.load %[[VAL_3]][] : memref<i32>
// CHECK_CANONICALIZED:           return %[[VAL_4]] : i32
wasm.func @i_am_a_block(%arg0 : !wasm<local ref to i32>) -> i32 {
  %1 = wasm.const 17 : i32
  wasm.local_set %arg0 : ref to i32 to %1 : i32
  wasm.block : {
    %2 = wasm.const 42 : i32
    wasm.local_set %arg0 : ref to i32 to %2 : i32
    wasm.block_return
  }> ^bb1
  ^bb1:
  %res = wasm.local_get %arg0 : ref to i32
  wasm.return %res : i32
}


// CHECK-LABEL:   func.func @func_0(
// CHECK-SAME:                      %[[ARG0:.*]]: i32) {
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
wasm.func nested @func_0(%arg0: !wasm<local ref to i32>) {
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

//// ============= Branch instructions etc ==========

// CHECK-LABEL:   func.func @branch_if_taken() -> i32 {
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_0:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_1:.*]] = arith.constant 2 : i32
// CHECK:           %[[VAL_2:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_3:.*]] = arith.cmpi ne, %[[VAL_1]], %[[VAL_2]] : i32
// CHECK:           cf.cond_br %[[VAL_3]], ^bb3(%[[VAL_0]] : i32), ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_4:.*]] = arith.constant 16 : i32
// CHECK:           %[[VAL_5:.*]] = arith.addi %[[VAL_0]], %[[VAL_4]] : i32
// CHECK:           cf.br ^bb3(%[[VAL_5]] : i32)
// CHECK:         ^bb3(%[[VAL_6:.*]]: i32):
// CHECK:           return %[[VAL_6]] : i32

// CHECK_CANONICALIZED-LABEL:   func.func @branch_if_taken() -> i32 {
// CHECK_CANONICALIZED:           %[[VAL_0:.*]] = arith.constant 1 : i32
// CHECK_CANONICALIZED:           return %[[VAL_0]] : i32

wasm.func nested @branch_if_taken() -> i32 {
  wasm.block : {
    %1 = wasm.const 1 : i32
    %2 = wasm.const 2 : i32
    wasm.branch_if %2 to level 0 with args(%1 : i32) else ^bb1
  ^bb1:  // pred: ^bb0
    %3 = wasm.const 16 : i32
    %4 = wasm.add %1 %3 : i32
    wasm.block_return %4 : i32
  }> ^bb1
^bb1(%0: i32):  // pred: ^bb0
  wasm.return %0 : i32
}

// CHECK-LABEL:   func.func @branch_if_continue() -> i32 {
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_0:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_2:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_3:.*]] = arith.cmpi ne, %[[VAL_1]], %[[VAL_2]] : i32
// CHECK:           cf.cond_br %[[VAL_3]], ^bb3(%[[VAL_0]] : i32), ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_4:.*]] = arith.constant 16 : i32
// CHECK:           %[[VAL_5:.*]] = arith.addi %[[VAL_0]], %[[VAL_4]] : i32
// CHECK:           cf.br ^bb3(%[[VAL_5]] : i32)
// CHECK:         ^bb3(%[[VAL_6:.*]]: i32):
// CHECK:           return %[[VAL_6]] : i32

// CHECK_CANONICALIZED-LABEL:   func.func @branch_if_continue() -> i32 {
// CHECK_CANONICALIZED:           %[[VAL_0:.*]] = arith.constant 17 : i32
// CHECK_CANONICALIZED:           return %[[VAL_0]] : i32
// CHECK_CANONICALIZED:         }
wasm.func nested @branch_if_continue() -> i32 {
  wasm.block : {
    %1 = wasm.const 1 : i32
    %2 = wasm.const 0 : i32
    wasm.branch_if %2 to level 0 with args(%1 : i32) else ^bb1
  ^bb1:  // pred: ^bb0
    %3 = wasm.const 16 : i32
    %4 = wasm.add %1 %3 : i32
    wasm.block_return %4 : i32
  }> ^bb1
^bb1(%0: i32):  // pred: ^bb0
  wasm.return %0 : i32
}

// CHECK-LABEL:   func.func @if(
// CHECK-SAME:                  %[[ARG0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_3:.*]] = arith.andi %[[VAL_1]], %[[VAL_2]] : i32
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_5:.*]] = arith.cmpi ne, %[[VAL_3]], %[[VAL_4]] : i32
// CHECK:           cf.cond_br %[[VAL_5]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           %[[VAL_6:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_7:.*]] = arith.constant 3 : i32
// CHECK:           %[[VAL_8:.*]] = arith.muli %[[VAL_6]], %[[VAL_7]] : i32
// CHECK:           %[[VAL_9:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_10:.*]] = arith.addi %[[VAL_8]], %[[VAL_9]] : i32
// CHECK:           cf.br ^bb3(%[[VAL_10]] : i32)
// CHECK:         ^bb2:
// CHECK:           %[[VAL_11:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_12:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_13:.*]] = arith.shrui %[[VAL_11]], %[[VAL_12]] : i32
// CHECK:           cf.br ^bb3(%[[VAL_13]] : i32)
// CHECK:         ^bb3(%[[VAL_14:.*]]: i32):
// CHECK:           return %[[VAL_14]] : i32
wasm.func nested @if(%arg0: !wasm<local ref to i32>) -> i32 {
  %1 = wasm.local_get %arg0 : ref to i32
  %2 = wasm.const 1 : i32
  %3 = wasm.and %1 %2 : i32
  "wasm.if"(%3)[^bb1] ({
    %5 = wasm.local_get %arg0 : ref to i32
    %6 = wasm.const 3 : i32
    %7 = wasm.mul %5 %6 : i32
    %8 = wasm.const 1 : i32
    %9 = wasm.add %7 %8 : i32
    wasm.block_return %9 : i32
  }, {
    %5 = wasm.local_get %arg0 : ref to i32
    %6 = wasm.const 1 : i32
    %7 = wasm.shr_u %5 by %6 bits : i32
    wasm.block_return %7 : i32
  }) : (i32) -> ()
^bb1(%4: i32):  // pred: ^bb0
  wasm.return %4 : i32
}

// CHECK-LABEL:   func.func @if_else(
// CHECK-SAME:      %[[ARG0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_4:.*]] = arith.andi %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           %[[VAL_5:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_6:.*]] = arith.cmpi ne, %[[VAL_4]], %[[VAL_5]] : i32
// CHECK:           cf.cond_br %[[VAL_6]], ^bb1(%[[VAL_1]] : i32), ^bb2(%[[VAL_1]] : i32)
// CHECK:         ^bb1(%[[VAL_7:.*]]: i32):
// CHECK:           %[[VAL_8:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_9:.*]] = arith.addi %[[VAL_7]], %[[VAL_8]] : i32
// CHECK:           cf.br ^bb2(%[[VAL_9]] : i32)
// CHECK:         ^bb2(%[[VAL_10:.*]]: i32):
// CHECK:           return %[[VAL_10]] : i32
wasm.func nested @if_else(%arg0: !wasm<local ref to i32>) -> i32 {
  %1 = wasm.local_get %arg0 : ref to i32
  %2 = wasm.local_get %arg0 : ref to i32
  %3 = wasm.const 1 : i32
  %4 = wasm.and %2 %3 : i32
  "wasm.if"(%4, %1)[^bb1] ({
  ^bb0(%arg1: i32):
    %6 = wasm.const 1 : i32
    %7 = wasm.add %arg1 %6 : i32
    wasm.block_return %7 : i32
  }, {
  }) : (i32, i32) -> ()
^bb1(%5: i32):  // pred: ^bb0
  wasm.return %5 : i32
}

// CHECK-LABEL:   func.func @if_if(
// CHECK-SAME:                     %[[ARG0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = math.cttz %[[VAL_1]] : i32
// CHECK:           %[[VAL_3:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_4:.*]] = arith.cmpi ne, %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           cf.cond_br %[[VAL_4]], ^bb1, ^bb4
// CHECK:         ^bb1:
// CHECK:           %[[VAL_5:.*]] = arith.constant 2 : i32
// CHECK:           %[[VAL_6:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_7:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_8:.*]] = arith.shrui %[[VAL_6]], %[[VAL_7]] : i32
// CHECK:           %[[VAL_9:.*]] = math.cttz %[[VAL_8]] : i32
// CHECK:           %[[VAL_10:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_11:.*]] = arith.cmpi ne, %[[VAL_9]], %[[VAL_10]] : i32
// CHECK:           cf.cond_br %[[VAL_11]], ^bb2(%[[VAL_5]] : i32), ^bb3(%[[VAL_5]] : i32)
// CHECK:         ^bb2(%[[VAL_12:.*]]: i32):
// CHECK:           %[[VAL_13:.*]] = arith.constant 2 : i32
// CHECK:           %[[VAL_14:.*]] = arith.addi %[[VAL_12]], %[[VAL_13]] : i32
// CHECK:           cf.br ^bb3(%[[VAL_14]] : i32)
// CHECK:         ^bb3(%[[VAL_15:.*]]: i32):
// CHECK:           cf.br ^bb5(%[[VAL_15]] : i32)
// CHECK:         ^bb4:
// CHECK:           %[[VAL_16:.*]] = arith.constant 1 : i32
// CHECK:           cf.br ^bb5(%[[VAL_16]] : i32)
// CHECK:         ^bb5(%[[VAL_17:.*]]: i32):
// CHECK:           return %[[VAL_17]] : i32
wasm.func nested @if_if(%arg0: !wasm<local ref to i32>) -> i32 {
  %1 = wasm.local_get %arg0 : ref to i32
  %2 = wasm.ctz %1 : i32
  "wasm.if"(%2)[^bb1] ({
    %4 = wasm.const 2 : i32
    %5 = wasm.local_get %arg0 : ref to i32
    %6 = wasm.const 1 : i32
    %7 = wasm.shr_u %5 by %6 bits : i32
    %8 = wasm.ctz %7 : i32
    "wasm.if"(%8, %4)[^bb1] ({
    ^bb0(%arg1: i32):
      %10 = wasm.const 2 : i32
      %11 = wasm.add %arg1 %10 : i32
      wasm.block_return %11 : i32
    }, {
    }) : (i32, i32) -> ()
  ^bb1(%9: i32):  // pred: ^bb0
    wasm.block_return %9 : i32
  }, {
    %4 = wasm.const 1 : i32
    wasm.block_return %4 : i32
  }) : (i32) -> ()
^bb1(%3: i32):  // pred: ^bb0
  wasm.return %3 : i32
}
