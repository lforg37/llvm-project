// RUN: mlir-opt %s | FileCheck %s

module {
  "wasm.import_func"() <{importName = "log", moduleName = "console", sym_name = "func_0", type = (i32) -> ()}> {sym_visibility = "nested"} : () -> ()
  "wasm.import_global"() <{importName = "from_js", moduleName = "env", sym_name = "global_0", type = i32}> {sym_visibility = "nested"} : () -> ()
  "wasm.func"() <{functionType = () -> (), sym_name = "func_1", sym_visibility = "nested"}> ({
  }) : () -> ()
  wasm.global @global_1 i32 : {
    %0 = wasm.empty_stack
    %1 = wasm.const 10 : i32 on %0
    %2 = wasm.pop i32 from %1
  }
  wasm.global @global_2 i32 mutable : {
    %0 = wasm.empty_stack
    %1 = wasm.const 10 : i32 on %0
    %2 = wasm.pop i32 from %1
  }
  wasm.global @global_3 i32 mutable : {
    %0 = wasm.empty_stack
    %1 = wasm.const 10 : i32 on %0
    %2 = wasm.pop i32 from %1
  }
}

// CHECK-LABEL:   wasm.import_func "log" from "console" as @func_0 {sym_visibility = "nested", type = (i32) -> ()}
// CHECK:         wasm.import_global "from_js" from "env" as @global_0 {sym_visibility = "nested", type = i32}

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> (), sym_name = "func_1", sym_visibility = "nested"}> ({
// CHECK:         }) : () -> ()

// CHECK-LABEL:   wasm.global @global_1 i32 : {
// CHECK:           %[[VAL_0:.*]] = wasm.empty_stack
// CHECK:           %[[VAL_1:.*]] = wasm.const 10 : i32 on %[[VAL_0]]
// CHECK:           %[[VAL_2:.*]] = wasm.pop i32 from %[[VAL_1]]
// CHECK:         }

// CHECK-LABEL:   wasm.global @global_2 i32 mutable : {
// CHECK:           %[[VAL_0:.*]] = wasm.empty_stack
// CHECK:           %[[VAL_1:.*]] = wasm.const 10 : i32 on %[[VAL_0]]
// CHECK:           %[[VAL_2:.*]] = wasm.pop i32 from %[[VAL_1]]
// CHECK:         }

// CHECK-LABEL:   wasm.global @global_3 i32 mutable : {
// CHECK:           %[[VAL_0:.*]] = wasm.empty_stack
// CHECK:           %[[VAL_1:.*]] = wasm.const 10 : i32 on %[[VAL_0]]
// CHECK:           %[[VAL_2:.*]] = wasm.pop i32 from %[[VAL_1]]
// CHECK:         }
