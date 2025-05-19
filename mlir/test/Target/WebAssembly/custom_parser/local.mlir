// RUN: mlir-opt %s | FileCheck %s

module {
  wasm.func nested @func_0() -> f32 {
    %0 = wasm.local f32
    %1 = wasm.local f32
    %2 = wasm.const 8.000000e+00 : f32
    %3 = wasm.const 1.200000e+01 : f32
    %4 = wasm.add %2 %3 : f32
    wasm.return %4 : f32
  }
  wasm.func nested @func_1() -> i32 {
    %0 = wasm.local i32
    %1 = wasm.local i32
    %2 = wasm.const 8 : i32
    %3 = wasm.const 12 : i32
    %4 = wasm.add %2 %3 : i32
    wasm.return %4 : i32
  }
  wasm.func nested @func_2(%arg0: i32) -> i32 {
    %0 = wasm.const 3 : i32
    wasm.return %0 : i32
  }
}

// CHECK-LABEL:   wasm.func nested @func_0() -> f32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local f32
// CHECK:           %[[VAL_1:.*]] = wasm.local f32
// CHECK:           %[[VAL_2:.*]] = wasm.const 8.000000e+00 : f32
// CHECK:           %[[VAL_3:.*]] = wasm.const 1.200000e+01 : f32
// CHECK:           %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : f32
// CHECK:           wasm.return %[[VAL_4]] : f32
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_1() -> i32 {
// CHECK:           %[[VAL_0:.*]] = wasm.local i32
// CHECK:           %[[VAL_1:.*]] = wasm.local i32
// CHECK:           %[[VAL_2:.*]] = wasm.const 8 : i32
// CHECK:           %[[VAL_3:.*]] = wasm.const 12 : i32
// CHECK:           %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : i32
// CHECK:           wasm.return %[[VAL_4]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.func nested @func_2(
// CHECK-SAME:      %[[VAL_0:.*]]: i32) -> i32 {
// CHECK:           %[[VAL_1:.*]] = wasm.const 3 : i32
// CHECK:           wasm.return %[[VAL_1]] : i32
// CHECK:         }
