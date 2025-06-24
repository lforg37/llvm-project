// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s

module {
  wasm.func nested @func_0() -> i64 {
    %0 = wasm.const 10 : i32
    %1 = wasm.extend_s %0 : i32 to i64
    wasm.return %1 : i64
  }
  wasm.func nested @func_1() -> i64 {
    %0 = wasm.const 10 : i32
    %1 = wasm.extend_u %0 : i32 to i64
    wasm.return %1 : i64
  }
  wasm.func nested @func_2() -> i32 {
    %0 = wasm.const 10 : i32
    %1 = wasm.extend8_s %0 : i32 to i32
    wasm.return %1 : i32
  }
  wasm.func nested @func_3() -> i32 {
    %0 = wasm.const 10 : i32
    %1 = wasm.extend16_s %0 : i32 to i32
    wasm.return %1 : i32
  }
  wasm.func nested @func_4() -> i64 {
    %0 = wasm.const 10 : i64
    %1 = wasm.extend8_s %0 : i64 to i64
    wasm.return %1 : i64
  }
  wasm.func nested @func_5() -> i64 {
    %0 = wasm.const 10 : i64
    %1 = wasm.extend16_s %0 : i64 to i64
    wasm.return %1 : i64
  }
  wasm.func nested @func_6() -> i64 {
    %0 = wasm.const 10 : i64
    %1 = wasm.extend32_s %0 : i64 to i64
    wasm.return %1 : i64
  }
}

// CHECK-LABEL:   func.func @func_0() -> i64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_1:.*]] = arith.extsi %[[VAL_0]] : i32 to i64
// CHECK:           return %[[VAL_1]] : i64

// CHECK-LABEL:   func.func @func_1() -> i64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_1:.*]] = arith.extui %[[VAL_0]] : i32 to i64
// CHECK:           return %[[VAL_1]] : i64
