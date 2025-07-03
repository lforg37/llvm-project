// RUN: wasabi %S/inputs/add_div.wasm --dump --output-type wasm-mlir | FileCheck --check-prefix=CHECK-WASM %s
// RUN: wasabi %S/inputs/add_div.wasm --dump --output-type std-mlir | FileCheck --check-prefix=CHECK-STD %s
// RUN: wasabi %S/inputs/add_div.wasm --dump | FileCheck --check-prefix=CHECK-LLVM %s

/* Input used for this test:
 (module $test.wasm
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (import "env" "twoTimes" (func $twoTimes (type 0)))
  (func $add (type 1) (param i32 i32) (result i32)
    local.get 0
    call $twoTimes
    local.get 1
    call $twoTimes
    i32.add
    i32.const 2
    i32.div_s)
  (export "add" (func $add)))
*/

// CHECK-WASM-LABEL:   wasm.import_func "twoTimes" from "env" as @func_0 {sym_visibility = "nested", type = (i32) -> i32}
// CHECK-WASM-LABEL:   wasm.func @add(
// CHECK-WASM-SAME:                   %[[VAL_0:.*]]: i32,
// CHECK-WASM-SAME:                   %[[VAL_1:.*]]: i32) -> i32 {
// CHECK-WASM:           %[[VAL_2:.*]] = wasm.call @func_0(%[[VAL_0]]) : (i32) -> i32
// CHECK-WASM:           %[[VAL_3:.*]] = wasm.call @func_0(%[[VAL_1]]) : (i32) -> i32
// CHECK-WASM:           %[[VAL_4:.*]] = wasm.add %[[VAL_2]] %[[VAL_3]] : i32
// CHECK-WASM:           %[[VAL_5:.*]] = wasm.const 2 : i32
// CHECK-WASM:           %[[VAL_6:.*]] = wasm.div_si %[[VAL_4]] %[[VAL_5]] : i32
// CHECK-WASM:           wasm.return %[[VAL_6]] : i32
// CHECK-WASM:         }

// CHECK-STD-LABEL:   llvm.func @"env::twoTimes"(i32) -> i32 attributes {sym_visibility = "private"}
// CHECK-STD-LABEL:   llvm.func @add(
// CHECK-STD-SAME:                   %[[VAL_0:.*]]: i32,
// CHECK-STD-SAME:                   %[[VAL_1:.*]]: i32) -> i32 {
// CHECK-STD:           %[[VAL_2:.*]] = llvm.mlir.constant(2 : i32) : i32
// CHECK-STD:           %[[VAL_3:.*]] = llvm.call @"env::twoTimes"(%[[VAL_0]]) : (i32) -> i32
// CHECK-STD:           %[[VAL_4:.*]] = llvm.call @"env::twoTimes"(%[[VAL_1]]) : (i32) -> i32
// CHECK-STD:           %[[VAL_5:.*]] = llvm.add %[[VAL_3]], %[[VAL_4]] : i32
// CHECK-STD:           %[[VAL_6:.*]] = llvm.sdiv %[[VAL_5]], %[[VAL_2]] : i32
// CHECK-STD:           llvm.return %[[VAL_6]] : i32
// CHECK-STD:         }

// CHECK-LLVM: declare i32 @"env::twoTimes"(i32)
// CHECK-LLVM: define i32 @add(i32 %[[ARG_0:.*]], i32 %[[ARG_1:.*]]) {
// CHECK-LLVM:         %[[VAL_0:.*]] = call i32 @"env::twoTimes"(i32 %[[ARG_0]])
// CHECK-LLVM:         %[[VAL_2:.*]] = call i32 @"env::twoTimes"(i32 %[[ARG_1]])
// CHECK-LLVM:         %[[VAL_4:.*]] = add i32 %[[VAL_0]], %[[VAL_2]]
// CHECK-LLVM:         %[[VAL_5:.*]] = sdiv i32 %[[VAL_4]], 2
// CHECK-LLVM:         ret i32 %[[VAL_5]]
