// XFAIL: *
// RUN: mlir-translate --import-wasm %S/inputs/table.wasm | FileCheck %s

/* Source code used to create this test:
(module
(table $t1 2 funcref)
(table $t2 2 4 funcref)
(table $t3 2 4 externref)
)
*/
