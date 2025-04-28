//===- TranslateFromWasm.cpp - Translating to C++ calls -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Target/Wasm/WasmImporter.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/LogicalResult.h"
#include <variant>

using namespace mlir;
using namespace mlir::wasm;

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
struct WasmEncodings {
  /// Byte encodings of types in wasm binaries
  /// These are defined in the wasm binary spec
  /// https://webassembly.github.io/spec/core/binary/types.html
  struct TypeEncoding {
    static constexpr uint8_t i32{0x7F};
    static constexpr uint8_t i64{0x7E};
    static constexpr uint8_t f32{0x7D};
    static constexpr uint8_t f64{0x7C};
    static constexpr uint8_t v128{0x7B};
    static constexpr uint8_t funcRef{0x70};
    static constexpr uint8_t externRef{0x6F};
    static constexpr uint8_t funcType{0x60};
  };

  struct ImportType {
    static constexpr uint8_t typeID{0x00};
    static constexpr uint8_t tableType{0x01};
    static constexpr uint8_t memType{0x02};
    static constexpr uint8_t globalType{0x03};
  };
};

struct GlobalTypeRecord {
  Type type;
  bool isMutable;
};

struct TypeIdxRecord {
  size_t id;
};

using ImportDesc = std::variant<TypeIdxRecord, TableType, LimitType, GlobalTypeRecord>;

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

  llvm::FailureOr<LimitType> parseLimit(MLIRContext* ctx) {
    auto limitLocation = getLocation();
    auto limitHeader = consumeByte();
    if (failed(limitHeader))
      return failure();
    if (*limitHeader > 1)
      return emitError(limitLocation, "Invalid limit header: ")
             << static_cast<int>(*limitHeader);
    auto minParse = parseUI32();
    if (failed(minParse))
      return failure();
    std::optional<uint32_t> max{std::nullopt};
    if (*limitHeader) {
      auto maxParse = parseUI32();
      if (failed(maxParse))
        return failure();
      max = *maxParse;
    }
    return LimitType::get(ctx, *minParse, max);
  }

  llvm::FailureOr<Type> parseValueType(MLIRContext *ctx) {
    auto typeLoc = getLocation();
    auto typeEncoding = consumeByte();
    if (failed(typeEncoding))
      return failure();
    switch (*typeEncoding) {
    case WasmEncodings::TypeEncoding::i32:
      return IntegerType::get(ctx, 32);
    case WasmEncodings::TypeEncoding::i64:
      return IntegerType::get(ctx, 64);
    case WasmEncodings::TypeEncoding::f32:
      return Float32Type::get(ctx);
    case WasmEncodings::TypeEncoding::f64:
      return Float64Type::get(ctx);
    case WasmEncodings::TypeEncoding::v128:
      return IntegerType::get(ctx, 128);
    case WasmEncodings::TypeEncoding::funcRef:
      return wasm::FuncRefType::get(ctx);
    case WasmEncodings::TypeEncoding::externRef:
      return wasm::ExternRefType::get(ctx);
    default:
      return emitError(typeLoc, "Invalid value type encoding: ")
             << static_cast<int>(*typeEncoding);
    }
  }

  llvm::FailureOr<GlobalTypeRecord> parseGlobalType(MLIRContext *ctx) {
    auto typeParsed = parseValueType(ctx);
    if (failed(typeParsed))
      return failure();
    auto mutLoc = getLocation();
    auto mutSpec = consumeByte();
    if (failed(mutSpec))
      return failure();
    if (*mutSpec > 1)
      return emitError(mutLoc, "Invalid global mutability specifier: ")
             << static_cast<int>(*mutSpec);
    return GlobalTypeRecord{*typeParsed, *mutSpec == 1};
  }

  llvm::FailureOr<TupleType> parseResultType(MLIRContext *ctx) {
    auto nParamsParsed = parseVectorSize();
    if (failed(nParamsParsed))
      return failure();
    auto nParams = *nParamsParsed;
    llvm::SmallVector<Type> res{};
    res.reserve(nParams);
    for (size_t i = 0; i < nParams; ++i) {
      auto parsedType = parseValueType(ctx);
      if (failed(parsedType))
        return failure();
      res.push_back(*parsedType);
    }
    return TupleType::get(ctx, res);
  }

  llvm::FailureOr<FunctionType> parseFunctionType(MLIRContext *ctx) {
    auto typeLoc = getLocation();
    auto funcTypeHeader = consumeByte();
    if (failed(funcTypeHeader))
      return failure();
    if (*funcTypeHeader != WasmEncodings::TypeEncoding::funcType)
      return emitError(typeLoc, "Invalid function type header byte. Expecting ")
             << WasmEncodings::TypeEncoding::funcType << " got "
             << static_cast<int>(*funcTypeHeader);
    auto inputTypes = parseResultType(ctx);
    if (failed(inputTypes))
      return failure();

    auto resTypes = parseResultType(ctx);
    if (failed(resTypes))
      return failure();

    return FunctionType::get(ctx, inputTypes->getTypes(), resTypes->getTypes());
  }

  llvm::FailureOr<TypeIdxRecord> parseTypeIndex() {
    auto res = parseUI32();
    if (failed(res))
      return failure();
    return TypeIdxRecord{*res};
  }

  llvm::FailureOr<TableType> parseTableType(MLIRContext *ctx) {
    auto elmTypeParse = parseValueType(ctx);
    if (failed(elmTypeParse))
      return failure();
    if (!isWasmRefType(*elmTypeParse))
      return emitError(getLocation(), "Invalid element type for table");
    auto limitParse = parseLimit(ctx);
    if (failed(limitParse))
      return failure();
    return TableType::get(ctx, *elmTypeParse, *limitParse);
  }

  llvm::FailureOr<ImportDesc> parseImportDesc(MLIRContext *ctx) {
    auto importLoc = getLocation();
    auto importType = consumeByte();
    auto packager = [](auto parseResult) -> llvm::FailureOr<ImportDesc> {
      if (llvm::failed(parseResult))
        return failure();
      return {*parseResult};
    };
    if (failed(importType))
      return failure();
    switch (*importType) {
    case WasmEncodings::ImportType::typeID:
      return packager(parseTypeIndex());
    case WasmEncodings::ImportType::tableType:
      return packager(parseTableType(ctx));
    case WasmEncodings::ImportType::memType:
      return packager(parseLimit(ctx));
    case WasmEncodings::ImportType::globalType:
      return packager(parseGlobalType(ctx));
    default:
      return emitError(importLoc, "Invalid import type descriptor: ")
             << static_cast<int>(*importType);
    }
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

  if (std::isgreater(decoded, std::numeric_limits<uint32_t>::max()))
    return emitError(getLocation()) << "literal does not fit on 32 bits";

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
      if (sectionShouldBeUnique(secType) && hasSection(secType))
        return emitError(loc,
                         "Trying to add a second instance of unique section");

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

  std::string getNewSymbolName(llvm::StringRef prefix, size_t id) const {
    return (prefix + llvm::Twine{id}).str();
  }

  std::string getNewFuncSymbolName() const {
    auto id = funcSymbols.size();
    return getNewSymbolName("func_", id);
  }

  std::string getNewGlobalSymbolName() const {
    auto id = globalSymbols.size();
    return getNewSymbolName("global_", id);
  }

  std::string getNewMemorySymbolName() const {
    auto id = memSymbols.size();
    return getNewSymbolName("mem_", id);
  }

  std::string getNewTableSymbolName() const {
    auto id = tableSymbols.size();
    return getNewSymbolName("table_", id);
  }

  template <WasmSectionType>
  LogicalResult parseSectionItem(ParserHead &);

  template <WasmSectionType section>
  LogicalResult parseSection() {
    auto secName = std::string{wasmSectionName<section>};
    auto sectionNameAttr =
        StringAttr::get(ctx, srcName.strref() + ":" + secName + "-SECTION");
    unsigned offset = 0;
    auto getLocation = [sectionNameAttr, &offset]() {
      return FileLineColLoc::get(sectionNameAttr, 0, offset);
    };
    auto secContent = registry.getContentForSection<section>();
    if (!secContent) {
      emitRemark(this->getLocation())
          << secName << " section is not present in file.";
      return success();
    }

    auto secSrc = secContent.value();
    ParserHead ph{secSrc, sectionNameAttr};
    auto nElemsParsed = ph.parseVectorSize();
    if (failed(nElemsParsed))
      return failure();
    auto nElems = *nElemsParsed;
    llvm::dbgs() << "Starting to parse " << nElems << " items for section "
                 << secName << ".\n";
    for (size_t i = 0; i < nElems; ++i) {
      if (failed(parseSectionItem<section>(ph)))
        return failure();
    }

    if (!ph.end())
      return emitError(getLocation(), "Unparsed garbage at end of section ")
             << secName;
    return success();
  }

  /// Handles the registration of a function import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName, TypeIdxRecord tid) {
    using llvm::Twine;
    if (tid.id >= funcTypes.size())
      return emitError(loc, "Invalid type id: ") << tid.id << ". Only " << funcTypes.size() << " type registration.";
    auto type = funcTypes[tid.id];
    auto symbol = getNewFuncSymbolName();
    auto funcOp = builder.create<FuncImportOp>(
        loc, symbol, moduleName, importName, type);
    funcOp.setVisibility(SymbolTable::Visibility::Nested);
    funcSymbols.push_back(funcOp.getSymNameAttr());
    return funcOp.verify();
  }

  /// Handles the registration of a memory import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName, LimitType limitType) {
    auto symbol = getNewMemorySymbolName();
    auto memOp = builder.create<MemImportOp>(loc, symbol, moduleName,
                                             importName, limitType);
    memOp.setVisibility(SymbolTable::Visibility::Nested);
    memSymbols.push_back(memOp.getSymNameAttr());
    return memOp.verify();
  }

  /// Handles the registration of a table import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName, TableType tableType) {
    auto symbol = getNewTableSymbolName();
    auto tableOp = builder.create<TableImportOp>(loc, symbol, moduleName,
                                                 importName, tableType);
    tableOp.setVisibility(SymbolTable::Visibility::Nested);
    tableSymbols.push_back(tableOp.getSymNameAttr());
    return tableOp.verify();
  }

  /// Handles the registration of a global variable import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName,
                            GlobalTypeRecord globalType) {
    auto symbol = getNewGlobalSymbolName();
    auto giOp =
        builder.create<GlobalImportOp>(loc, symbol, moduleName, importName,
                                       globalType.type, globalType.isMutable);
    giOp.setVisibility(SymbolTable::Visibility::Nested);
    globalSymbols.push_back(giOp.getSymNameAttr());
    return giOp.verify();
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

    mOp = builder.create<ModuleOp>(getLocation());
    builder.setInsertionPointToStart(
        &mOp.getBodyRegion().front());
    auto parsingTypes = parseSection<WasmSectionType::TYPE>();
    if (failed(parsingTypes))
      return;

    auto parsingImports = parseSection<WasmSectionType::IMPORT>();
    if (failed(parsingImports))
      return;

    auto parsingFunctions = parseSection<WasmSectionType::FUNCTION>();
    if (failed(parsingFunctions))
      return;

    auto parsingTables = parseSection<WasmSectionType::TABLE>();
    if (failed(parsingTables))
      return;

    auto parsingMems = parseSection<WasmSectionType::MEMORY>();
    if (failed(parsingMems))
      return;
    auto parsingGlobals = parseSection<WasmSectionType::GLOBAL>();
    if (failed(parsingGlobals))
      return;
  }

  ModuleOp getModule() { return mOp; }

private:
  mlir::StringAttr srcName;
  OpBuilder builder;
  llvm::SmallVector<FunctionType> funcTypes;
  llvm::SmallVector<StringAttr> funcSymbols;
  llvm::SmallVector<StringAttr> globalSymbols;
  llvm::SmallVector<StringAttr> memSymbols;
  llvm::SmallVector<StringAttr> tableSymbols;
  MLIRContext *ctx;
  ModuleOp mOp;
  SectionRegistry registry;
};

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::IMPORT>(ParserHead &ph) {
  auto importLoc = ph.getLocation();
  auto moduleName = ph.parseName();
  if (failed(moduleName))
    return failure();

  auto importName = ph.parseName();
  if (failed(importName))
    return failure();

  auto import = ph.parseImportDesc(ctx);
  if (failed(import))
    return failure();

  return std::visit(
      [this, importLoc, &moduleName, &importName](auto import) {
        return visitImport(importLoc, *moduleName, *importName, import);
      },
      *import);
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::TABLE>(ParserHead &ph) {
  auto opLocation = ph.getLocation();
  auto tableType = ph.parseTableType(ctx);
  if (failed(tableType))
    return failure();
  llvm::dbgs() << "  Parsed table description: " << *tableType << '\n';
  auto symbol = builder.getStringAttr(getNewTableSymbolName());
  auto tableOp = builder.create<TableOp>(opLocation, symbol, TypeAttr::get(*tableType));
  tableOp.setVisibility(SymbolTable::Visibility::Nested);
  tableSymbols.push_back(symbol);
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::FUNCTION>(ParserHead &ph) {
  auto opLoc = ph.getLocation();
  auto typeIdxParsed = ph.parseLiteral<uint32_t>();
  if (failed(typeIdxParsed))
    return failure();
  auto typeIdx = *typeIdxParsed;
  if (typeIdx >= funcTypes.size())
    return emitError(getLocation(), "Invalid type index: ") << typeIdx;
  auto symbol = getNewFuncSymbolName();
  auto funcOp = builder.create<FuncOp>(
      opLoc, symbol, funcTypes[typeIdx]);
  funcOp.setVisibility(SymbolTable::Visibility::Nested);
  funcSymbols.push_back(funcOp.getSymNameAttr());
  return funcOp.verify();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::TYPE>(ParserHead &ph) {
  auto funcType = ph.parseFunctionType(ctx);
  if (failed(funcType))
    return failure();
  llvm::dbgs() << "Parsed function type " << *funcType << '\n';
  funcTypes.push_back(*funcType);
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::MEMORY>(ParserHead &ph) {
  auto opLocation = ph.getLocation();
  auto memory = ph.parseLimit(ctx);
  if (failed(memory))
    return failure();

  llvm::dbgs() << "  Registering memory " << *memory << '\n';
  auto symbol = getNewMemorySymbolName();
  auto memOp = builder.create<MemOp>(opLocation, symbol, *memory);
  memOp.setVisibility(SymbolTable::Visibility::Nested);
  memSymbols.push_back(memOp.getSymNameAttr());
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::GLOBAL>(ParserHead &ph) {
  auto globalLocation = ph.getLocation();
  auto globalTypeParsed = ph.parseGlobalType(ctx);
  if (failed(globalTypeParsed)) {
    return failure();
  }
  auto globalType = *globalTypeParsed;
  auto symbol = builder.getStringAttr(getNewGlobalSymbolName());
  auto globalOp = builder.create<wasm::GlobalOp>(
      globalLocation, symbol, globalType.type, globalType.isMutable, false);
  globalOp.setVisibility(SymbolTable::Visibility::Nested);
  return success();
}
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
