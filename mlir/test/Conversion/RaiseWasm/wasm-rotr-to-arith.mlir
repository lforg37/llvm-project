// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// Given:
// %res = wasm.rotr %val by %bits bits : i32
//
// Produce:
// res = (val >> (bits & 31)) | (val << (-bits & 31))

// CHECK-LABEL:   func.func @rotr_i32(
// CHECK-SAME:      %[[ARG0:.*]]: i32,
// CHECK-SAME:      %[[ARG1:.*]]: i32) -> i32 {

// Storage etc
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>

// (val >> (bits & 31))
// CHECK:           %[[VAL_4:.*]] = arith.constant 31 : i32
// CHECK:           %[[VAL_5:.*]] = arith.andi %[[VAL_3]], %[[VAL_4]] : i32
// CHECK:           %[[VAL_6:.*]] = arith.shrui %[[VAL_2]], %[[VAL_5]] : i32

// (val << (-bits & 31))
// CHECK:           %[[VAL_7:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_8:.*]] = "llvm.intr.usub.with.overflow"(%[[VAL_7]], %[[VAL_3]]) : (i32, i32) -> !llvm.struct<(i32, i1)>
// CHECK:           %[[VAL_9:.*]] = llvm.extractvalue %[[VAL_8]][0] : !llvm.struct<(i32, i1)>
// CHECK:           %[[VAL_10:.*]] = llvm.extractvalue %[[VAL_8]][1] : !llvm.struct<(i32, i1)>
// CHECK:           cf.cond_br %[[VAL_10]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_11:.*]] = arith.andi %[[VAL_9]], %[[VAL_4]] : i32
// CHECK:           %[[VAL_12:.*]] = arith.shli %[[VAL_2]], %[[VAL_11]] : i32
// CHECK:           %[[VAL_13:.*]] = arith.ori %[[VAL_6]], %[[VAL_12]] : i32
// CHECK:           return %[[VAL_13]] : i32

wasm.func nested @rotr_i32(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32

    %op = wasm.rotr %v0 by %v1 bits : i32
    wasm.return %op : i32
}

// CHECK-LABEL:   func.func @rotr_i64(
// CHECK-SAME:      %[[ARG0:.*]]: i64,
// CHECK-SAME:      %[[ARG1:.*]]: i64) -> i64 {

// Storage etc
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>

// (val >> (bits & 63))
// CHECK:           %[[VAL_4:.*]] = arith.constant 63 : i64
// CHECK:           %[[VAL_5:.*]] = arith.andi %[[VAL_3]], %[[VAL_4]] : i64
// CHECK:           %[[VAL_6:.*]] = arith.shrui %[[VAL_2]], %[[VAL_5]] : i64

// (val << (-bits & 63))
// CHECK:           %[[VAL_7:.*]] = arith.constant 0 : i64
// CHECK:           %[[VAL_8:.*]] = "llvm.intr.usub.with.overflow"(%[[VAL_7]], %[[VAL_3]]) : (i64, i64) -> !llvm.struct<(i64, i1)>
// CHECK:           %[[VAL_9:.*]] = llvm.extractvalue %[[VAL_8]][0] : !llvm.struct<(i64, i1)>
// CHECK:           %[[VAL_10:.*]] = llvm.extractvalue %[[VAL_8]][1] : !llvm.struct<(i64, i1)>
// CHECK:           cf.cond_br %[[VAL_10]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           wasm.trap
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           %[[VAL_11:.*]] = arith.andi %[[VAL_9]], %[[VAL_4]] : i64
// CHECK:           %[[VAL_12:.*]] = arith.shli %[[VAL_2]], %[[VAL_11]] : i64
// CHECK:           %[[VAL_13:.*]] = arith.ori %[[VAL_6]], %[[VAL_12]] : i64
// CHECK:           return %[[VAL_13]] : i64

wasm.func nested @rotr_i64(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64

    %op = wasm.rotr %v0 by %v1 bits : i64
    wasm.return %op : i64
}
