// RUN: mlir-opt %s --raise-wasm-mlir | FileCheck %s

// CHECK-LABEL:   func.func @convert_i32_u_to_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_1:.*]] = arith.uitofp %[[VAL_0]] : i32 to f32
// CHECK:           return %[[VAL_1]] : f32
wasm.func @convert_i32_u_to_f32() -> f32 {
  %0 = wasm.const 10 : i32
  %1 = wasm.convert_u %0 : i32 to f32
  wasm.return %1 : f32
}

// CHECK-LABEL:   func.func @convert_i32_s_to_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 42 : i32
// CHECK:           %[[VAL_1:.*]] = arith.sitofp %[[VAL_0]] : i32 to f32
// CHECK:           return %[[VAL_1]] : f32
wasm.func @convert_i32_s_to_f32() -> f32 {
  %0 = wasm.const 42 : i32
  %1 = wasm.convert_s %0 : i32 to f32
  wasm.return %1 : f32
}

// CHECK-LABEL:   func.func @convert_i64_u_to_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 17 : i64
// CHECK:           %[[VAL_1:.*]] = arith.uitofp %[[VAL_0]] : i64 to f32
// CHECK:           return %[[VAL_1]] : f32
wasm.func @convert_i64_u_to_f32() -> f32 {
  %0 = wasm.const 17 : i64
  %1 = wasm.convert_u %0 : i64 to f32
  wasm.return %1 : f32
}

// CHECK-LABEL:   func.func @convert_i64s_to_f32() -> f32 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i64
// CHECK:           %[[VAL_1:.*]] = arith.sitofp %[[VAL_0]] : i64 to f32
// CHECK:           return %[[VAL_1]] : f32
wasm.func @convert_i64s_to_f32() -> f32 {
  %0 = wasm.const 10 : i64
  %1 = wasm.convert_s %0 : i64 to f32
  wasm.return %1 : f32
}

// CHECK-LABEL:   func.func @convert_i32_u_to_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i32
// CHECK:           %[[VAL_1:.*]] = arith.uitofp %[[VAL_0]] : i32 to f64
// CHECK:           return %[[VAL_1]] : f64
wasm.func @convert_i32_u_to_f64() -> f64 {
  %0 = wasm.const 10 : i32
  %1 = wasm.convert_u %0 : i32 to f64
  wasm.return %1 : f64
}

// CHECK-LABEL:   func.func @convert_i32_s_to_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 42 : i32
// CHECK:           %[[VAL_1:.*]] = arith.sitofp %[[VAL_0]] : i32 to f64
// CHECK:           return %[[VAL_1]] : f64
wasm.func @convert_i32_s_to_f64() -> f64 {
  %0 = wasm.const 42 : i32
  %1 = wasm.convert_s %0 : i32 to f64
  wasm.return %1 : f64
}

// CHECK-LABEL:   func.func @convert_i64_u_to_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 17 : i64
// CHECK:           %[[VAL_1:.*]] = arith.uitofp %[[VAL_0]] : i64 to f64
// CHECK:           return %[[VAL_1]] : f64
wasm.func @convert_i64_u_to_f64() -> f64 {
  %0 = wasm.const 17 : i64
  %1 = wasm.convert_u %0 : i64 to f64
  wasm.return %1 : f64
}

// CHECK-LABEL:   func.func @convert_i64s_to_f64() -> f64 {
// CHECK:           %[[VAL_0:.*]] = arith.constant 10 : i64
// CHECK:           %[[VAL_1:.*]] = arith.sitofp %[[VAL_0]] : i64 to f64
// CHECK:           return %[[VAL_1]] : f64
wasm.func @convert_i64s_to_f64() -> f64 {
  %0 = wasm.const 10 : i64
  %1 = wasm.convert_s %0 : i64 to f64
  wasm.return %1 : f64
}