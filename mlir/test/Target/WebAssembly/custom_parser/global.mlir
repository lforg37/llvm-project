// RUN: mlir-opt %s | FileCheck %s

module {
  wasm.global @global_1 i32 : {
    %0 = wasm.const 10 : i32
    wasm.return %0 : i32
  }
  wasm.global @global_2 i32 mutable : {
    %0 = wasm.const 17 : i32
    wasm.return %0 : i32
  }
  wasm.global @global_3 i32 mutable : {
    %0 = wasm.const 10 : i32
    wasm.return %0 : i32
  }
}

// CHECK-LABEL:   wasm.global @global_1 i32 : {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.global @global_2 i32 mutable : {
// CHECK:           %[[VAL_0:.*]] = wasm.const 17 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }

// CHECK-LABEL:   wasm.global @global_3 i32 mutable : {
// CHECK:           %[[VAL_0:.*]] = wasm.const 10 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }
