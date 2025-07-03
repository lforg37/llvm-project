// RUN: wasabi %s --dump --input-type wasm-mlir | FileCheck %s

module {
  wasm.import_func "twoTimes" from "env" as @func_0 {sym_visibility = "nested", type = (i32) -> i32}
  wasm.func @add(%arg0: i32, %arg1: i32) -> i32 {
    %0 = wasm.call @func_0(%arg0) : (i32) -> i32
    %1 = wasm.call @func_0(%arg1) : (i32) -> i32
    %2 = wasm.add %0 %1 : i32
    %3 = wasm.const 2 : i32
    %4 = wasm.div_si %2 %3 : i32
    wasm.return %4 : i32
  }
}

// CHECK: declare i32 @"env::twoTimes"(i32)
// CHECK: define i32 @add(i32 %[[ARG_0:.*]], i32 %[[ARG_1:.*]]) {
// CHECK:         %[[VAL_0:.*]] = call i32 @"env::twoTimes"(i32 %[[ARG_0]])
// CHECK:         %[[VAL_2:.*]] = call i32 @"env::twoTimes"(i32 %[[ARG_1]])
// CHECK:         %[[VAL_4:.*]] = add i32 %[[VAL_0]], %[[VAL_2]]
// CHECK:         %[[VAL_5:.*]] = sdiv i32 %[[VAL_4]], 2
// CHECK:         ret i32 %[[VAL_5]]
