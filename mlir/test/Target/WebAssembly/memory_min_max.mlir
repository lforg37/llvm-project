// RUN: mlir-translate --import-wasm %S/inputs/memory_min_max.wasm | FileCheck %s

/* Source code used to create this test:
(module (memory 0 65536))
*/

// CHECK-LABEL:  "wasm.memory"() <{limits = !wasm<limit[0:65536]>, sym_name = "mem_0", sym_visibility = "nested"}> : () -> ()
