// RUN: mlir-opt %s --raise-wasm-mlir --wasm-mlir-to-embedder | FileCheck %s

wasm.func nested @func_1(%arg0: !wasm<local ref to i32>, %arg1: !wasm<local ref to i32>) -> i32 {
    %v0 = wasm.local_get %arg0 : ref to i32
    %v1 = wasm.local_get %arg1 : ref to i32
    %0 = wasm.add %v0 %v1 : i32
    wasm.return %0 : i32
}

// CHECK:   func.func private @wasm.trap()

// CHECK-LABEL:   func.func @func_1(
// CHECK-SAME:                      %[[ARG0:.*]]: i32,
// CHECK-SAME:                      %[[ARG1:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i32>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i32>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i32>
// CHECK:           %[[VAL_4:.*]] = "llvm.intr.uadd.with.overflow"(%[[VAL_2]], %[[VAL_3]]) : (i32, i32) -> !llvm.struct<(i32, i1)>
// CHECK:           %[[VAL_5:.*]] = llvm.extractvalue %[[VAL_4]][0] : !llvm.struct<(i32, i1)>
// CHECK:           %[[VAL_6:.*]] = llvm.extractvalue %[[VAL_4]][1] : !llvm.struct<(i32, i1)>
// CHECK:           cf.cond_br %[[VAL_6]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           call @wasm.trap() : () -> ()
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           return %[[VAL_5]] : i32

wasm.func nested @func_2(%arg0: !wasm<local ref to i64>, %arg1: !wasm<local ref to i64>) -> i64 {
    %v0 = wasm.local_get %arg0 : ref to i64
    %v1 = wasm.local_get %arg1 : ref to i64
    %0 = wasm.add %v0 %v1 : i64
    wasm.return %0 : i64
}

// CHECK-LABEL:   func.func @func_2(
// CHECK-SAME:                      %[[ARG0:.*]]: i64,
// CHECK-SAME:                      %[[ARG1:.*]]: i64) -> i64 {
// CHECK:           %[[VAL_0:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG1]], %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_1:.*]] = memref.alloca() : memref<i64>
// CHECK:           memref.store %[[ARG0]], %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_2:.*]] = memref.load %[[VAL_1]][] : memref<i64>
// CHECK:           %[[VAL_3:.*]] = memref.load %[[VAL_0]][] : memref<i64>
// CHECK:           %[[VAL_4:.*]] = "llvm.intr.uadd.with.overflow"(%[[VAL_2]], %[[VAL_3]]) : (i64, i64) -> !llvm.struct<(i64, i1)>
// CHECK:           %[[VAL_5:.*]] = llvm.extractvalue %[[VAL_4]][0] : !llvm.struct<(i64, i1)>
// CHECK:           %[[VAL_6:.*]] = llvm.extractvalue %[[VAL_4]][1] : !llvm.struct<(i64, i1)>
// CHECK:           cf.cond_br %[[VAL_6]], ^bb1, ^bb2
// CHECK:         ^bb1:
// CHECK:           call @wasm.trap() : () -> ()
// CHECK:           cf.br ^bb2
// CHECK:         ^bb2:
// CHECK:           return %[[VAL_5]] : i64
