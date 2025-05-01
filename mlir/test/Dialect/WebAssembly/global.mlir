// RUN: mlir-translate --import-wasm %S/inputs/global.wasm | FileCheck %s

/* Source code used to create this test:
(module
(import "console" "log" (func $log (param i32)))

;; import a global variable from js
(global $imported_glob (import "env" "from_js") i32)

;; create a global variable
(global $normal_glob i32(i32.const 10))
(global $glob_mut (mut i32) (i32.const 10))
(global $glob_mut_ext (mut i32) (i32.const 10))

(export "blob" (global $glob_mut_ext))

(func $main
;; load both global variables onto the stack
global.get $imported_glob
global.get $normal_glob

i32.add ;; add up both globals

global.get $glob_mut
global.get $glob_mut_ext
i32.add
i32.add
call $log ;; log the result
)
(start $main)
)
*/

// CHECK-LABEL:   wasm.import_func "log" from "console" as @func_0 {sym_visibility = "nested", type = (i32) -> ()}
// CHECK:         wasm.import_global "from_js" from "env" as @global_0 {sym_visibility = "nested", type = i32}

// CHECK-LABEL:   "wasm.func"() <{functionType = () -> (), sym_name = "func_1", sym_visibility = "nested"}> ({
// CHECK:           %[[VAL_0:.*]] = wasm.empty_stack
// CHECK:           wasm.return
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
// CHECK:         wasm.export @global_3 as @blob
