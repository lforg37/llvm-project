// RUN: wasabi %s --dump --input-type wasm-mlir | FileCheck %s

module {
  wasmssa.import_func "twoTimes" from "env" as @func_0 {sym_visibility = "nested", type = (i32) -> i32}
  wasmssa.func @add(%arg0: !wasmssa<local ref to i32>, %arg1: !wasmssa<local ref to i32>) -> i32 {
    %arg0_value = wasmssa.local_get %arg0 : !wasmssa<local ref to i32>
    %0 = wasmssa.call @func_0(%arg0_value) : (i32) -> i32
    %arg1_value = wasmssa.local_get %arg1 : !wasmssa<local ref to i32>
    %1 = wasmssa.call @func_0(%arg1_value) : (i32) -> i32
    %2 = wasmssa.add %0 %1 : i32
    %3 = wasmssa.const 2 : i32
    %4 = wasmssa.div_si %2 %3 : i32
    wasmssa.return %4 : i32
  }
}

// CHECK: declare i32 @"env::twoTimes"(i32)
// CHECK: define i32 @add(i32 %[[ARG_0:.*]], i32 %[[ARG_1:.*]]) {
// CHECK-LLVM-SAME:    %[[VAL_0:.*]] = alloca i32, i64 1, align 4
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
