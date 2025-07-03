// RUN: mlir-opt --split-input-file %s --raise-wasm-mlir -o - | FileCheck %s

// Given:
// %res = wasm.rotr %val by %bits bits : i32
//
// Produce:
// res = (val >> (bits & 31)) | (val << (-bits & 31))

// CHECK-LABEL:   func.func @rotr_i32(
// CHECK-SAME:      %[[VALREF:.*]]: i32,
// CHECK-SAME:      %[[BITSREF:.*]]: i32) -> i32 {

// Storage etc
// CHECK-DAG:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK-DAG:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK-DAG:           memref.store %[[VALREF]], %[[VAL_0]][] : memref<i32>
// CHECK-DAG:           memref.store %[[BITSREF]], %[[VAL_1]][] : memref<i32>
// CHECK-DAG:           %[[VAL:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK-DAG:           %[[BITS:.*]] = memref.load %[[VAL_1]][] : memref<i32>

// (val >> (bits & 31))
// CHECK:           %[[THIRTY_ONE:.*]] = arith.constant 31 : i32
// CHECK:           %[[LHS_AND:.*]] = arith.andi %[[BITS]], %[[THIRTY_ONE]] : i32
// CHECK:           %[[SHRU:.*]] = arith.shrui %[[VAL]], %[[LHS_AND]] : i32

// (val << (-bits & 31))
// CHECK:           %[[ZERO:.*]] = arith.constant 0 : i32
// CHECK:           %[[NEG_BITS:.*]] = arith.subi %[[ZERO]], %[[BITS]] : i32
// CHECK:           %[[RHS_AND:.*]] = arith.andi %[[NEG_BITS]], %[[THIRTY_ONE]] : i32
// CHECK:           %[[SHL:.*]] = arith.shli %[[VAL]], %[[RHS_AND]] : i32

// CHECK:           %[[RES:.*]] = arith.ori %[[SHRU]], %[[SHL]] : i32
// CHECK:           return %[[RES]] : i32
// CHECK:         }
wasm.func nested @rotr_i32(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32
        
    %op = wasm.rotr %v0 by %v1 bits : i32
    wasm.return %op : i32
}

// Same as above, but with 64 bits.
// CHECK-LABEL:   func.func @rotr_i64(
// CHECK-SAME:      %[[VALREF:.*]]: i64,
// CHECK-SAME:      %[[BITSREF:.*]]: i64) -> i64 {

// Storage etc
// CHECK-DAG:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK-DAG:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK-DAG:           memref.store %[[VALREF]], %[[VAL_0]][] : memref<i64>
// CHECK-DAG:           memref.store %[[BITSREF]], %[[VAL_1]][] : memref<i64>
// CHECK-DAG:           %[[VAL:.*]] = memref.load %[[VAL_0]][] : memref<i64>
// CHECK-DAG:           %[[BITS:.*]] = memref.load %[[VAL_1]][] : memref<i64>

// (val >> (bits & 63))
// CHECK:           %[[SIXTY_THREE:.*]] = arith.constant 63 : i64
// CHECK:           %[[LHS_AND:.*]] = arith.andi %[[BITS]], %[[SIXTY_THREE]] : i64
// CHECK:           %[[SHRU:.*]] = arith.shrui %[[VAL]], %[[LHS_AND]] : i64

// (val << (-bits & 63))
// CHECK:           %[[ZERO:.*]] = arith.constant 0 : i64
// CHECK:           %[[NEG_BITS:.*]] = arith.subi %[[ZERO]], %[[BITS]] : i64
// CHECK:           %[[RHS_AND:.*]] = arith.andi %[[NEG_BITS]], %[[SIXTY_THREE]] : i64
// CHECK:           %[[SHL:.*]] = arith.shli %[[VAL]], %[[RHS_AND]] : i64

// Form final result.
// CHECK:           %[[RES:.*]] = arith.ori %[[SHRU]], %[[SHL]] : i64
// CHECK:           return %[[RES]] : i64
// CHECK:         }
wasm.func nested @rotr_i64(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64

    %op = wasm.rotr %v0 by %v1 bits : i64
    wasm.return %op : i64
}
