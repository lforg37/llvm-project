//===- WasmBinaryEncoding.h - Byte encodings for Wasm binary format ===----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Define encodings for WebAssembly instructions, types, etc from the
// WebAssembly binary format.
//
// Each encoding is defined in the WebAssembly binary specification.
//
//===----------------------------------------------------------------------===//
#ifndef MLIR_TARGET_WASMBINARYENCODING
#define MLIR_TARGET_WASMBINARYENCODING

#include <cstddef>
namespace mlir {
struct WasmBinaryEncoding {
  /// Byte encodings of types in WASM binaries
  struct Type {
    static constexpr std::byte emptyBlockType{0x40};
    static constexpr std::byte funcType{0x60};
    static constexpr std::byte externRef{0x6F};
    static constexpr std::byte funcRef{0x70};
    static constexpr std::byte v128{0x7B};
    static constexpr std::byte f64{0x7C};
    static constexpr std::byte f32{0x7D};
    static constexpr std::byte i64{0x7E};
    static constexpr std::byte i32{0x7F};
  };
};
} // namespace mlir

#endif
