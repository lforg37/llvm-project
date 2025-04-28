//===- TranslateFromWasm.cpp - Translating to C++ calls -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/Target/Wasm/WasmImporter.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/LogicalResult.h"

using namespace mlir;
namespace {
class ParserHead {
public:
  ParserHead(llvm::StringRef src, StringAttr name) : head{src}, locName{name} {}
  ParserHead(ParserHead const &other) = delete;
  ParserHead(ParserHead &&) = delete;

  auto getLocation() const {
    return FileLineColLoc::get(locName, 0, anchorOffset + offset);
  }

  llvm::FailureOr<llvm::StringRef> consumeNBytes(size_t nBytes) {
    if (nBytes > size()) {
      return emitError(getLocation(), "trying to extract ")
             << nBytes << "bytes when only " << size() << "are avilables";
    }
    auto res = head.slice(offset, offset + nBytes);
    offset += nBytes;
    return res;
  }

  llvm::FailureOr<uint8_t> consumeByte() {
    auto res = consumeNBytes(1);
    if (failed(res))
      return failure();
    return *res->bytes_begin();
  }

  template <typename T>
  llvm::FailureOr<T> parseLiteral();

  llvm::FailureOr<uint32_t> parseVectorSize();

private:
  // TODO: This is equivalent to parseLiteral<uint32_t> and could be removed
  // if parseLiteral specialisation were moved here, but default GCC on Ubuntu
  // 22.04 has bug with template specialisation in class declaration
  inline llvm::FailureOr<uint32_t> parseUI32();

public:
  llvm::FailureOr<llvm::StringRef> parseName() {
    auto size = parseVectorSize();
    if (failed(size)) {
      return failure();
    }
    return consumeNBytes(*size);
  }


  bool end() const { return curHead().empty(); }

private:
  llvm::StringRef curHead() const { return head.drop_front(offset); }

  size_t size() const { return head.size() - offset; }

  llvm::StringRef head;
  StringAttr locName;
  unsigned anchorOffset{0};
  unsigned offset{0};
};
template <>
llvm::FailureOr<uint32_t> ParserHead::parseLiteral<uint32_t>() {
  char const *error = nullptr;
  uint32_t res{0};
  unsigned encodingSize{0};
  auto src = curHead();
  auto decoded = llvm::decodeULEB128(src.bytes_begin(), &encodingSize,
                                     src.bytes_end(), &error);
  if (error)
    return emitError(getLocation(), error);

  if (std::isgreater(decoded, std::numeric_limits<uint32_t>::max())) {
    return emitError(getLocation()) << "literal does not fit on 32 bits";
  }
  res = static_cast<uint32_t>(decoded);
  offset += encodingSize;
  return res;
}
llvm::FailureOr<uint32_t> ParserHead::parseVectorSize() {
  return parseLiteral<uint32_t>();
}
inline llvm::FailureOr<uint32_t> ParserHead::parseUI32() {
  return parseLiteral<uint32_t>();
}

class WasmBinaryParser {
private:
  auto getLocation(int offset = 0) const {
    return FileLineColLoc::get(srcName, 0, offset);
  }

public:
  WasmBinaryParser(llvm::SourceMgr &sourceMgr, MLIRContext *ctx)
      : builder{ctx}, ctx{ctx} {
    ctx->loadAllAvailableDialects();
    if (sourceMgr.getNumBuffers() != 1) {
      emitError(UnknownLoc::get(ctx), "One source file should be provided");
      return;
    }
    auto sourceBufId = sourceMgr.getMainFileID();
    auto source = sourceMgr.getMemoryBuffer(sourceBufId)->getBuffer();
    srcName = StringAttr::get(
      ctx, sourceMgr.getMemoryBuffer(sourceBufId)->getBufferIdentifier());

    auto parser = ParserHead{source, srcName};
    auto const wasmHeader = StringRef{"\0asm", 4};
    auto magicLoc = parser.getLocation();
    auto magic = parser.consumeNBytes(wasmHeader.size());
    if (failed(magic) || magic->compare(wasmHeader)) {
      emitError(magicLoc,
                "Source file does not contain valid Wasm header.");
      return;
    }
    auto const expectedVersionString = StringRef{"\1\0\0\0", 4};
    auto versionLoc = parser.getLocation();
    auto version = parser.consumeNBytes(expectedVersionString.size());
    if (failed(version))
      return;
    if (version->compare(expectedVersionString)) {
      emitError(versionLoc,
                "Unsupported Wasm version. Only version 1 is supported.");
      return;
    }
  }

  ModuleOp getModule() { return mOp; }

private:
  mlir::StringAttr srcName;
  OpBuilder builder;
  MLIRContext *ctx;
  ModuleOp mOp;
};
} // namespace

namespace mlir {
namespace wasm {
OwningOpRef<ModuleOp> importWebAssemblyToModule(llvm::SourceMgr &source,
                                                MLIRContext *context) {
  WasmBinaryParser wBN{source, context};
  auto mOp = wBN.getModule();
  if (mOp)
    return {mOp};

  return {nullptr};
}
} // namespace wasm
} // namespace mlir
