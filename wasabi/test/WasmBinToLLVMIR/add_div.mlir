// RUN: wasabi %S/inputs/add_div.wasm --dump --output-type wasm-mlir | FileCheck --check-prefix=CHECK-WASM %s
// RUN: wasabi %S/inputs/add_div.wasm --dump --output-type llvm-mlir | FileCheck --check-prefix=CHECK-STD %s
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

// CHECK-WASM-LABEL:   wasmssa.import_func "twoTimes" from "env" as @func_0 {sym_visibility = "nested", type = (i32) -> i32}

// CHECK-WASM-LABEL:   wasmssa.func @add(
// CHECK-WASM-SAME:                      %[[ARG0:.*]]: !wasmssa<local ref to i32>,
// CHECK-WASM-SAME:                      %[[ARG1:.*]]: !wasmssa<local ref to i32>) -> i32 {
// CHECK-WASM:           %[[VAL_0:.*]] = wasmssa.local_get %[[ARG0]] :  ref to i32
// CHECK-WASM:           %[[VAL_1:.*]] = wasmssa.call @func_0(%[[VAL_0]]) : (i32) -> i32
// CHECK-WASM:           %[[VAL_2:.*]] = wasmssa.local_get %[[ARG1]] :  ref to i32
// CHECK-WASM:           %[[VAL_3:.*]] = wasmssa.call @func_0(%[[VAL_2]]) : (i32) -> i32
// CHECK-WASM:           %[[VAL_4:.*]] = wasmssa.add %[[VAL_1]] %[[VAL_3]] : i32
// CHECK-WASM:           %[[VAL_5:.*]] = wasmssa.const 2 : i32
// CHECK-WASM:           %[[VAL_6:.*]] = wasmssa.div_si %[[VAL_4]] %[[VAL_5]] : i32
// CHECK-WASM:           wasmssa.return %[[VAL_6]] : i32

// CHECK-STD-LABEL:   llvm.func @"env::twoTimes"(i32) -> i32 attributes {sym_visibility = "private"}

// CHECK-STD-LABEL:   llvm.func @add(
// CHECK-STD-SAME:                   %[[ARG0:.*]]: i32,
// CHECK-STD-SAME:                   %[[ARG1:.*]]: i32) -> i32 {
// CHECK-STD:           %[[VAL_0:.*]] = llvm.mlir.constant(2 : i32) : i32
// CHECK-STD:           %[[VAL_1:.*]] = llvm.mlir.constant(1 : index) : i64
// CHECK-STD:           %[[VAL_2:.*]] = llvm.alloca %[[VAL_1]] x i32 : (i64) -> !llvm.ptr
// CHECK-STD:           llvm.store %[[ARG1]], %[[VAL_2]] : i32, !llvm.ptr
// CHECK-STD:           %[[VAL_3:.*]] = llvm.alloca %[[VAL_1]] x i32 : (i64) -> !llvm.ptr
// CHECK-STD:           llvm.store %[[ARG0]], %[[VAL_3]] : i32, !llvm.ptr
// CHECK-STD:           %[[VAL_4:.*]] = llvm.load %[[VAL_3]] : !llvm.ptr -> i32
// CHECK-STD:           %[[VAL_5:.*]] = llvm.call @"env::twoTimes"(%[[VAL_4]]) : (i32) -> i32
// CHECK-STD:           %[[VAL_6:.*]] = llvm.load %[[VAL_2]] : !llvm.ptr -> i32
// CHECK-STD:           %[[VAL_7:.*]] = llvm.call @"env::twoTimes"(%[[VAL_6]]) : (i32) -> i32
// CHECK-STD:           %[[VAL_8:.*]] = llvm.add %[[VAL_5]], %[[VAL_7]] : i32
// CHECK-STD:           %[[VAL_9:.*]] = llvm.sdiv %[[VAL_8]], %[[VAL_0]] : i32
// CHECK-STD:           llvm.return %[[VAL_9]] : i32

// CHECK-LLVM: declare i32 @"env::twoTimes"(i32)
// CHECK-LLVM: define i32 @add(i32 %[[ARG_0:.*]], i32 %[[ARG_1:.*]]) {
// CHECK-LLVM:    %[[VAL_0:.*]] = alloca i32, i64 1, align 4
// CHECK-LLVM:         store i32 %[[VAL_1:.*]], ptr %[[VAL_0]], align 4
// CHECK-LLVM:         %[[VAL_2:.*]] = alloca i32, i64 1, align 4
// CHECK-LLVM:         store i32 %[[VAL_3:.*]], ptr %[[VAL_2]], align 4
// CHECK-LLVM:         %[[VAL_4:.*]] = load i32, ptr %[[VAL_2]], align 4
// CHECK-LLVM:         %[[VAL_5:.*]] = call i32 @"env::twoTimes"(i32 %[[VAL_4]])
// CHECK-LLVM:         %[[VAL_6:.*]] = load i32, ptr %[[VAL_0]], align 4
// CHECK-LLVM:         %[[VAL_7:.*]] = call i32 @"env::twoTimes"(i32 %[[VAL_6]])
// CHECK-LLVM:         %[[VAL_8:.*]] = add i32 %[[VAL_5]], %[[VAL_7]]
// CHECK-LLVM:         %[[VAL_9:.*]] = sdiv i32 %[[VAL_8]], 2
// CHECK-LLVM:         ret i32 %[[VAL_9]]
