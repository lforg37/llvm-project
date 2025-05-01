// RUN: mlir-translate --import-wasm %S/inputs/table.wasm | FileCheck %s

/* Source code used to create this test:
(module
(table $t1 2 funcref)
(table $t2 2 4 funcref)
(table $t3 2 4 externref)
)
*/

// CHECK-LABEL:   "wasm.table"() <{sym_name = "table_0", type = !wasm<tabletype !wasm.funcref "[2:]">}> {sym_visibility = "nested"} : () -> ()
// CHECK:         "wasm.table"() <{sym_name = "table_1", type = !wasm<tabletype !wasm.funcref "[2:4]">}> {sym_visibility = "nested"} : () -> ()
// CHECK:         "wasm.table"() <{sym_name = "table_2", type = !wasm<tabletype !wasm.externref "[2:4]">}> {sym_visibility = "nested"} : () -> ()
