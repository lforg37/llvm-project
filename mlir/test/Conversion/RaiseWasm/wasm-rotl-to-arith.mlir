// RUN: mlir-opt --split-input-file %s --raise-wasmssa.mlir -o - | FileCheck %s

// Given:
// %res = wasmssa.sa.rotl %val by %bits bits : i32
//
// Produce:
// res = (val >> (bits & 31)) | (val << (-bits & 31))

// CHECK-LABEL:   func.func @rotl_i32(
// CHECK-SAME:      %[[ARG0:.*]]: i32,
// CHECK-SAME:      %[[ARG1:.*]]: i32) -> i32 {

// Storage etc
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>

// (val << (bits & 31))
// CHECK:           %[[VAL_4:.*]] = arith.constant 31 : i32
// CHECK:           %[[VAL_5:.*]] = arith.andi %[[VAL_3]], %[[VAL_4]] : i32
// CHECK:           %[[VAL_6:.*]] = arith.shli %[[VAL_2]], %[[VAL_5]] : i32

// (val >> (-bits & 31))
// CHECK:           %[[VAL_7:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_8:.*]] = wasmssa.sub %[[VAL_7]] %[[VAL_3]] : i32
// CHECK:           %[[VAL_9:.*]] = arith.andi %[[VAL_8]], %[[VAL_4]] : i32
// CHECK:           %[[VAL_10:.*]] = arith.shrui %[[VAL_2]], %[[VAL_9]] : i32
// CHECK:           %[[VAL_11:.*]] = arith.ori %[[VAL_6]], %[[VAL_10]] : i32
// CHECK:           return %[[VAL_11]] : i32

wasmssa.func nested @rotl_i32(%arg0: !wasmssa.local ref to i32>, %arg1: !wasmssa.local ref to i32>) -> i32 {
    %v0 = wasmssa.local_get %arg0 : ref to i32
    %v1 = wasmssa.local_get %arg1 : ref to i32

    %op = wasmssa.rotl %v0 by %v1 bits : i32
    wasmssa.return %op : i32
}

// Same as above, but with 64 bits.
// CHECK-LABEL:   func.func @rotl_i64(
// CHECK-SAME:      %[[ARG0:.*]]: i64,
// CHECK-SAME:      %[[ARG1:.*]]: i64) -> i64 {

// Storage etc
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>

// (val << (bits & 63))
// CHECK:           %[[VAL_4:.*]] = arith.constant 63 : i64
// CHECK:           %[[VAL_5:.*]] = arith.andi %[[VAL_3]], %[[VAL_4]] : i64
// CHECK:           %[[VAL_6:.*]] = arith.shli %[[VAL_2]], %[[VAL_5]] : i64

// (val >> (-bits & 63))
// CHECK:           %[[VAL_7:.*]] = arith.constant 0 : i64
// CHECK:           %[[VAL_8:.*]] = wasmssa.sub %[[VAL_7]] %[[VAL_3]] : i64
// CHECK:           %[[VAL_9:.*]] = arith.andi %[[VAL_8]], %[[VAL_4]] : i64

// Form final result.
// CHECK:           %[[VAL_10:.*]] = arith.shrui %[[VAL_2]], %[[VAL_9]] : i64
// CHECK:           %[[VAL_11:.*]] = arith.ori %[[VAL_6]], %[[VAL_10]] : i64
// CHECK:           return %[[VAL_11]] : i64

wasmssa.func nested @rotl_i64(%arg0: !wasmssa.local ref to i64>, %arg1: !wasmssa.local ref to i64>) -> i64 {
    %v0 = wasmssa.local_get %arg0 : ref to i64
    %v1 = wasmssa.local_get %arg1 : ref to i64

    %op = wasmssa.rotl %v0 by %v1 bits : i64
    wasmssa.return %op : i64
}
