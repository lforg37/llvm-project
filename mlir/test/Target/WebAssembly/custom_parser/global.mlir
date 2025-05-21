// RUN: mlir-opt %s | FileCheck %s

module {
  wasm.import_global "glob" from "my_module" as @global_0 {sym_visibility = "nested", type = i32}

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
  wasm.global @global_4 i32 : {
    %0 = wasm.global_get @global_0 : i32
    wasm.return %0 : i32
  }
}

// CHECK-LABEL:   wasm.import_global "glob" from "my_module" as @global_0 {sym_visibility = "nested", type = i32}

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

// CHECK-LABEL:   wasm.global @global_4 i32 : {
// CHECK:           %[[VAL_0:.*]] = wasm.global_get @global_0 : i32
// CHECK:           wasm.return %[[VAL_0]] : i32
// CHECK:         }
