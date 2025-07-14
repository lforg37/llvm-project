// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s
// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir --canonicalize -o - | FileCheck --check-prefix=CHECK-CANONICAL %s

module {
  wasmssa.func nested @func_0() {
    wasmssa.loop : {
      wasmssa.block_return
    }> ^bb1
  ^bb1:  // pred: ^bb0
    wasmssa.return
  }
}

// CHECK-LABEL:   module {
// CHECK:           func.func @func_0() {
// CHECK:             cf.br ^bb1
// CHECK:           ^bb1:
// CHECK:             cf.br ^bb2
// CHECK:           ^bb2:
// CHECK:             return
// CHECK:           }

// CHECK-CANONICAL-LABEL:  func.func @func_0() {
// CHECK-CANONICAL:             return
// CHECK-CANONICAL:           }

// -----

module {
  wasmssa.func nested @func_0() -> i32 {
    %0 = wasmssa.local of type i32
    wasmssa.loop : {
      %1 = wasmssa.local_get %0 : ref to i32
      %2 = wasmssa.const 10 : i32
      %3 = wasmssa.lt_si %1 %2 : i32 -> i32
      wasmssa.block_return %3 : i32
    }> ^bb1
  ^bb1(%1: i32):  // pred: ^bb0
    wasmssa.return %1 : i32
  }
}
// CHECK-LABEL:   func.func @func_0() -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK:           memref.store %[[VAL_1]], %[[VAL_0]][] : memref<i32>
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_4:.*]] = arith.cmpi slt, %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           %[[VAL_5:.*]] = arith.extui %[[VAL_4]] : i1 to i32
// CHECK:           cf.br ^bb2(%[[VAL_5]] : i32)
// CHECK:         ^bb2(%[[VAL_6:.*]]: i32):
// CHECK:           return %[[VAL_6]] : i32
// CHECK:         }

// CHECK-CANONICAL-LABEL:   func.func @func_0() -> i32 {
// CHECK-CANONICAL:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK-CANONICAL:           %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK-CANONICAL:           %[[VAL_2:.*]] = memref.alloca() : memref<i32>
// CHECK-CANONICAL:           memref.store %[[VAL_1]], %[[VAL_2]][] : memref<i32>
// CHECK-CANONICAL:           %[[VAL_3:.*]] = memref.load %[[VAL_2]][] : memref<i32>
// CHECK-CANONICAL:           %[[VAL_4:.*]] = arith.cmpi slt, %[[VAL_3]], %[[VAL_0]] : i32
// CHECK-CANONICAL:           %[[VAL_5:.*]] = arith.extui %[[VAL_4]] : i1 to i32
// CHECK-CANONICAL:           return %[[VAL_5]] : i32

// -----

module {
  wasmssa.func nested @func_0() {
    %0 = wasmssa.local of type i32
    wasmssa.loop : {
      %1 = wasmssa.local_get %0 : ref to i32
      %2 = wasmssa.const 10 : i32
      %3 = wasmssa.lt_si %1 %2 : i32 -> i32
      wasmssa.branch_if %3 to level 0 else ^bb1
    ^bb1:  // pred: ^bb0
      wasmssa.block_return
    }> ^bb1
  ^bb1:  // pred: ^bb0
    wasmssa.return
  }
}

// CHECK-LABEL:   func.func @func_0() {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK:           memref.store %[[VAL_1]], %[[VAL_0]][] : memref<i32>
// CHECK:           cf.br ^bb1
// CHECK:         ^bb1:
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_4:.*]] = arith.cmpi slt, %[[VAL_2]], %[[VAL_3]] : i32
// CHECK:           %[[VAL_5:.*]] = arith.extui %[[VAL_4]] : i1 to i32
// CHECK:           %[[VAL_6:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_7:.*]] = arith.cmpi ne, %[[VAL_5]], %[[VAL_6]] : i32
// CHECK:           cf.cond_br %[[VAL_7]], ^bb1, ^bb2
// CHECK:         ^bb2:
// CHECK:           cf.br ^bb3
// CHECK:         ^bb3:
// CHECK:           return
// CHECK:         }

// CHECK-CANONICAL-LABEL:   func.func @func_0() {
// CHECK-CANONICAL:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK-CANONICAL:           %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK-CANONICAL:           %[[VAL_2:.*]] = memref.alloca() : memref<i32>
// CHECK-CANONICAL:           memref.store %[[VAL_1]], %[[VAL_2]][] : memref<i32>
// CHECK-CANONICAL:           cf.br ^bb1
// CHECK-CANONICAL:         ^bb1:
// CHECK-CANONICAL:           %[[VAL_3:.*]] = memref.load %[[VAL_2]][] : memref<i32>
// CHECK-CANONICAL:           %[[VAL_4:.*]] = arith.cmpi slt, %[[VAL_3]], %[[VAL_0]] : i32
// CHECK-CANONICAL:           cf.cond_br %[[VAL_4]], ^bb1, ^bb2
// CHECK-CANONICAL:         ^bb2:
// CHECK-CANONICAL:           return

// -----

module {
  wasmssa.func nested @func_0() {
    %0 = wasmssa.local of type i32
    %1 = wasmssa.local of type i32
    wasmssa.loop : {
      %2 = wasmssa.local_get %0 : ref to i32
      %3 = wasmssa.const 1 : i32
      %4 = wasmssa.ge_ui %2 %3 : i32 -> i32
      wasmssa.local_set %0 : ref to i32 to %4 : i32
      wasmssa.loop : {
        %8 = wasmssa.const 12 : i32
        %9 = wasmssa.local_get %0 : ref to i32
        %10 = wasmssa.gt_si %8 %9 : i32 -> i32
        wasmssa.branch_if %10 to level 0 else ^bb1
      ^bb1:  // pred: ^bb0
        wasmssa.block_return %8 : i32
      }> ^bb1
    ^bb1(%5: i32):  // pred: ^bb0
      %6 = wasmssa.const 10 : i32
      %7 = wasmssa.lt_si %5 %6 : i32 -> i32
      wasmssa.branch_if %7 to level 0 else ^bb2
    ^bb2:  // pred: ^bb1
      wasmssa.block_return
    }> ^bb1
  ^bb1:  // pred: ^bb0
    wasmssa.return
  }
}

// CHECK-LABEL:     func.func @func_0() {
// CHECK:             %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:             %[[VAL_1:.*]] = arith.constant 0 : i32
// CHECK:             memref.store %[[VAL_1]], %[[VAL_0]][] : memref<i32>
// CHECK:             %[[VAL_2:.*]] = memref.alloca() : memref<i32>
// CHECK:             %[[VAL_3:.*]] = arith.constant 0 : i32
// CHECK:             memref.store %[[VAL_3]], %[[VAL_2]][] : memref<i32>
// CHECK:             cf.br ^bb1
// CHECK:           ^bb1:
// CHECK:             %[[VAL_4:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:             %[[VAL_5:.*]] = arith.constant 1 : i32
// CHECK:             %[[VAL_6:.*]] = arith.cmpi uge, %[[VAL_4]], %[[VAL_5]] : i32
// CHECK:             %[[VAL_7:.*]] = arith.extui %[[VAL_6]] : i1 to i32
// CHECK:             memref.store %[[VAL_7]], %[[VAL_0]][] : memref<i32>
// CHECK:             cf.br ^bb2
// CHECK:           ^bb2:
// CHECK:             %[[VAL_8:.*]] = arith.constant 12 : i32
// CHECK:             %[[VAL_9:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:             %[[VAL_10:.*]] = arith.cmpi sgt, %[[VAL_8]], %[[VAL_9]] : i32
// CHECK:             %[[VAL_11:.*]] = arith.extui %[[VAL_10]] : i1 to i32
// CHECK:             %[[VAL_12:.*]] = arith.constant 0 : i32
// CHECK:             %[[VAL_13:.*]] = arith.cmpi ne, %[[VAL_11]], %[[VAL_12]] : i32
// CHECK:             cf.cond_br %[[VAL_13]], ^bb2, ^bb3
// CHECK:           ^bb3:
// CHECK:             cf.br ^bb4(%[[VAL_8]] : i32)
// CHECK:           ^bb4(%[[VAL_14:.*]]: i32):
// CHECK:             %[[VAL_15:.*]] = arith.constant 10 : i32
// CHECK:             %[[VAL_16:.*]] = arith.cmpi slt, %[[VAL_14]], %[[VAL_15]] : i32
// CHECK:             %[[VAL_17:.*]] = arith.extui %[[VAL_16]] : i1 to i32
// CHECK:             %[[VAL_18:.*]] = arith.constant 0 : i32
// CHECK:             %[[VAL_19:.*]] = arith.cmpi ne, %[[VAL_17]], %[[VAL_18]] : i32
// CHECK:             cf.cond_br %[[VAL_19]], ^bb1, ^bb5
// CHECK:           ^bb5:
// CHECK:             cf.br ^bb6
// CHECK:           ^bb6:
// CHECK:             return
// CHECK:           }
// CHECK:         }


// CHECK-CANONICAL-LABEL:     func.func @func_0() {
// CHECK-CANONICAL:             %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK-CANONICAL:             %[[VAL_1:.*]] = arith.constant 12 : i32
// CHECK-CANONICAL:             %[[VAL_2:.*]] = arith.constant 1 : i32
// CHECK-CANONICAL:             %[[VAL_3:.*]] = arith.constant 0 : i32
// CHECK-CANONICAL:             %[[VAL_4:.*]] = memref.alloca() : memref<i32>
// CHECK-CANONICAL:             memref.store %[[VAL_3]], %[[VAL_4]][] : memref<i32>
// CHECK-CANONICAL:             cf.br ^bb1
// CHECK-CANONICAL:           ^bb1:
// CHECK-CANONICAL:             %[[VAL_5:.*]] = memref.load %[[VAL_4]][] : memref<i32>
// CHECK-CANONICAL:             %[[VAL_6:.*]] = arith.cmpi uge, %[[VAL_5]], %[[VAL_2]] : i32
// CHECK-CANONICAL:             %[[VAL_7:.*]] = arith.extui %[[VAL_6]] : i1 to i32
// CHECK-CANONICAL:             memref.store %[[VAL_7]], %[[VAL_4]][] : memref<i32>
// CHECK-CANONICAL:             cf.br ^bb2
// CHECK-CANONICAL:           ^bb2:
// CHECK-CANONICAL:             %[[VAL_8:.*]] = memref.load %[[VAL_4]][] : memref<i32>
// CHECK-CANONICAL:             %[[VAL_9:.*]] = arith.cmpi slt, %[[VAL_8]], %[[VAL_1]] : i32
// CHECK-CANONICAL:             cf.cond_br %[[VAL_9]], ^bb2, ^bb3(%[[VAL_1]] : i32)
// CHECK-CANONICAL:           ^bb3(%[[VAL_10:.*]]: i32):
// CHECK-CANONICAL:             %[[VAL_11:.*]] = arith.cmpi slt, %[[VAL_10]], %[[VAL_0]] : i32
// CHECK-CANONICAL:             cf.cond_br %[[VAL_11]], ^bb1, ^bb4
// CHECK-CANONICAL:           ^bb4:
// CHECK-CANONICAL:             return
