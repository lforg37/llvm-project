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
using section_id_t = uint8_t;
enum struct WasmSectionType : section_id_t {
  CUSTOM = 0,
  TYPE = 1,
  IMPORT = 2,
  FUNCTION = 3,
  TABLE = 4,
  MEMORY = 5,
  GLOBAL = 6,
  EXPORT = 7,
  START = 8,
  ELEMENT = 9,
  CODE = 10,
  DATA = 11,
  DATACOUNT = 12
};

constexpr section_id_t highestWasmSectionID{
  static_cast<section_id_t>(WasmSectionType::DATACOUNT)};

#define APPLY_WASM_SEC_TRANSFORM                                               \
  WASM_SEC_TRANSFORM(CUSTOM)                                                   \
  WASM_SEC_TRANSFORM(TYPE)                                                     \
  WASM_SEC_TRANSFORM(IMPORT)                                                   \
  WASM_SEC_TRANSFORM(FUNCTION)                                                 \
  WASM_SEC_TRANSFORM(TABLE)                                                    \
  WASM_SEC_TRANSFORM(MEMORY)                                                   \
  WASM_SEC_TRANSFORM(GLOBAL)                                                   \
  WASM_SEC_TRANSFORM(EXPORT)                                                   \
  WASM_SEC_TRANSFORM(START)                                                    \
  WASM_SEC_TRANSFORM(ELEMENT)                                                  \
  WASM_SEC_TRANSFORM(CODE)                                                     \
  WASM_SEC_TRANSFORM(DATA)                                                     \
  WASM_SEC_TRANSFORM(DATACOUNT)

template <WasmSectionType>
constexpr const char *wasmSectionName = "";

#define WASM_SEC_TRANSFORM(section)                                            \
  template <>                                                                  \
  constexpr const char *wasmSectionName<WasmSectionType::section> = #section;
APPLY_WASM_SEC_TRANSFORM
#undef WASM_SEC_TRANSFORM

constexpr bool sectionShouldBeUnique(WasmSectionType secType) {
  return secType != WasmSectionType::CUSTOM;
}
class ParserHead {
public:
  ParserHead(llvm::StringRef src, StringAttr name) : head{src}, locName{name} {}
  ParserHead(ParserHead &&) = default;
private:
  ParserHead(ParserHead const &other) = default;

public:

  auto getLocation() const {
    return FileLineColLoc::get(locName, 0, anchorOffset + offset);
  }

  llvm::FailureOr<llvm::StringRef> consumeNBytes(size_t nBytes) {
    if (nBytes > size())
      return emitError(getLocation(), "trying to extract ")
             << nBytes << "bytes when only " << size() << "are avilables";

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
    if (failed(size))
      return failure();

    return consumeNBytes(*size);
  }

  llvm::FailureOr<WasmSectionType> parseWasmSectionType() {
    auto id = consumeByte();
    if (failed(id))
      return failure();
    if (*id > highestWasmSectionID)
      return emitError(getLocation(), "Invalid section ID: ")
             << static_cast<int>(*id);
    return static_cast<WasmSectionType>(*id);
  }

  bool end() const { return curHead().empty(); }

  ParserHead copy() const {
    return *this;
  }

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
  struct SectionRegistry {
    using section_location_t = llvm::StringRef;

    std::array<llvm::SmallVector<section_location_t>, highestWasmSectionID+1> registry;

    template <WasmSectionType SecType>
    std::conditional_t<sectionShouldBeUnique(SecType),
                       std::optional<section_location_t>,
                       llvm::ArrayRef<section_location_t>>
    getContentForSection() const {
      constexpr auto idx = static_cast<size_t>(SecType);
      if constexpr (sectionShouldBeUnique(SecType)) {
        return registry[idx].empty() ? std::nullopt
                                     : std::make_optional(registry[idx][0]);
      } else {
        return registry[idx];
      }
    }

    bool hasSection(WasmSectionType secType) const {
      return !registry[static_cast<size_t>(secType)].empty();
    }

    ///
    /// @returns success if registration valid, failure in case registration
    /// can't be done (if another section of same type already exist and this
    /// section type should only be present once)
    ///
    LogicalResult registerSection(WasmSectionType secType,
                                  section_location_t location, Location loc) {
      if (sectionShouldBeUnique(secType) && hasSection(secType)) {
        return emitError(loc,
                         "Trying to add a second instance of unique section");
      }
      registry[static_cast<size_t>(secType)].push_back(location);
      emitRemark(loc, "Adding section with section ID ")
          << static_cast<uint8_t>(secType);
      return success();
    }

    LogicalResult populateFromBody(ParserHead ph) {
      while (!ph.end()) {
        auto sectionLoc = ph.getLocation();
        auto secType = ph.parseWasmSectionType();
        if (failed(secType))
          return failure();

        auto secSizeParsed = ph.parseLiteral<uint32_t>();
        if (failed(secSizeParsed))
          return failure();

        auto secSize = *secSizeParsed;
        auto sectionContent = ph.consumeNBytes(secSize);
        if (failed(sectionContent))
          return failure();

        auto registration =
            registerSection(*secType, *sectionContent, sectionLoc);

        if (failed(registration))
          return failure();

      }
      return success();
    }
  };

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
    auto fillRegistry = registry.populateFromBody(parser.copy());
    if (failed(fillRegistry))
      return;
  }

  ModuleOp getModule() { return mOp; }

private:
  mlir::StringAttr srcName;
  OpBuilder builder;
  MLIRContext *ctx;
  ModuleOp mOp;
  SectionRegistry registry;
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
