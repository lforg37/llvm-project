// RUN: mlir-opt %s | FileCheck %s

module {
  wasm.import_func "foo" from "my_module" as @func_0 {sym_visibility = "nested", type = (i32) -> ()}
  wasm.import_func "bar" from "my_module" as @func_1 {sym_visibility = "nested", type = (i32) -> ()}
  wasm.import_table "table" from "my_module" as @table_0 {sym_visibility = "nested", type = !wasm<tabletype !wasm.funcref [2:]>}
  wasm.import_mem "mem" from "my_module" as @mem_0 {limits = !wasm<limit[2:]>, sym_visibility = "nested"}
  wasm.import_global "glob" from "my_module" as @global_0 {sym_visibility = "nested", type = i32}
  wasm.import_global "glob_mut" from "my_other_module" as @global_1 {isMutable, sym_visibility = "nested", type = i32}
}

// CHECK-LABEL:   wasm.import_func "foo" from "my_module" as @func_0 {sym_visibility = "nested", type = (i32) -> ()}
// CHECK:         wasm.import_func "bar" from "my_module" as @func_1 {sym_visibility = "nested", type = (i32) -> ()}
// CHECK:         wasm.import_table "table" from "my_module" as @table_0 {sym_visibility = "nested", type = !wasm<tabletype !wasm.funcref [2:]>}
// CHECK:         wasm.import_mem "mem" from "my_module" as @mem_0 {limits = !wasm<limit[2:]>, sym_visibility = "nested"}
// CHECK:         wasm.import_global "glob" from "my_module" as @global_0 {sym_visibility = "nested", type = i32}
// CHECK:         wasm.import_global "glob_mut" from "my_other_module" as @global_1 {isMutable, sym_visibility = "nested", type = i32}
