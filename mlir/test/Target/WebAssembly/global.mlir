// XFAIL: *
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

// CHECK-FAIL
