// RUN: yaml2obj %S/inputs/memory_min_eq_max.yaml.wasm -o - | mlir-translate --import-wasm | FileCheck %s

/* Source code used to create this test:
(module (memory 0 0))
*/

// CHECK-LABEL:   "wasm.memory"() <{limits = !wasm<limit[0:0]>, sym_name = "mem_0", sym_visibility = "nested"}> : () -> ()
