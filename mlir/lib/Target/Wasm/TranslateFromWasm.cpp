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
#include "mlir/IR/BuiltinAttributeInterfaces.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Target/Wasm/WasmImporter.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FormatVariadic.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/LogicalResult.h"

#include <optional>
#include <type_traits>
#include <utility>
#include <variant>

#define DEBUG_TYPE "wasm-translate"

// Statistics.
STATISTIC(numFunctionSectionItems, "Parsed functions");
STATISTIC(numGlobalSectionItems, "Parsed globals");
STATISTIC(numMemorySectionItems, "Parsed memories");
STATISTIC(numTableSectionItems, "Parsed tables");

static_assert(CHAR_BIT == 8, "This code expects std::byte to be exactly 8 bits");

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
  struct OpCode {
    // Control instructions
    static constexpr std::byte block{0x02};
    static constexpr std::byte call{0x10};

    // Variable instructions
    static constexpr std::byte localGet{0x20};
    static constexpr std::byte localSet{0x21};
    static constexpr std::byte localTee{0x22};
    static constexpr std::byte globalGet{0x23};

    // Numerical constants
    static constexpr std::byte constI32{0x41};
    static constexpr std::byte constI64{0x42};
    static constexpr std::byte constFP32{0x43};
    static constexpr std::byte constFP64{0x44};

    // Numerical ops
    static constexpr std::byte eqI32{0x46};
    static constexpr std::byte neI32{0x47};
    static constexpr std::byte ltSI32{0x48};
    static constexpr std::byte ltUI32{0x49};
    static constexpr std::byte gtSI32{0x4A};
    static constexpr std::byte gtUI32{0x4B};
    static constexpr std::byte leSI32{0x4C};
    static constexpr std::byte leUI32{0x4D};
    static constexpr std::byte geSI32{0x4E};
    static constexpr std::byte geUI32{0x4F};
    static constexpr std::byte addI32{0x6A};
    static constexpr std::byte subI32{0x6B};
    static constexpr std::byte mulI32{0x6C};
    static constexpr std::byte divSI32{0x6d};
    static constexpr std::byte divUI32{0x6e};
    static constexpr std::byte remSI32{0x6f};
    static constexpr std::byte remUI32{0x70};
    static constexpr std::byte andI32{0x71};
    static constexpr std::byte orI32{0x72};
    static constexpr std::byte xorI32{0x73};
    static constexpr std::byte shlI32{0x74};
    static constexpr std::byte shr_sI32{0x75};
    static constexpr std::byte shr_uI32{0x76};
    static constexpr std::byte rotlI32{0x77};
    static constexpr std::byte rotrI32{0x78};

    static constexpr std::byte eqI64{0x51};
    static constexpr std::byte neI64{0x52};
    static constexpr std::byte ltSI64{0x53};
    static constexpr std::byte ltUI64{0x54};
    static constexpr std::byte gtSI64{0x55};
    static constexpr std::byte gtUI64{0x56};
    static constexpr std::byte leSI64{0x57};
    static constexpr std::byte leUI64{0x58};
    static constexpr std::byte geSI64{0x59};
    static constexpr std::byte geUI64{0x5A};
    static constexpr std::byte addI64{0x7C};
    static constexpr std::byte subI64{0x7D};
    static constexpr std::byte mulI64{0x7E};
    static constexpr std::byte divSI64{0x7F};
    static constexpr std::byte divUI64{0x80};
    static constexpr std::byte remSI64{0x81};
    static constexpr std::byte remUI64{0x82};
    static constexpr std::byte andI64{0x83};
    static constexpr std::byte orI64{0x84};
    static constexpr std::byte xorI64{0x85};
    static constexpr std::byte shlI64{0x86};
    static constexpr std::byte shr_sI64{0x87};
    static constexpr std::byte shr_uI64{0x88};
    static constexpr std::byte rotlI64{0x89};
    static constexpr std::byte rotrI64{0x8A};

    static constexpr std::byte eqF32{0x5B};
    static constexpr std::byte neF32{0x5C};
    static constexpr std::byte ltF32{0x5D};
    static constexpr std::byte gtF32{0x5E};
    static constexpr std::byte leF32{0x5F};
    static constexpr std::byte geF32{0x60};
    static constexpr std::byte addF32{0x92};
    static constexpr std::byte subF32{0x93};
    static constexpr std::byte mulF32{0x94};
    static constexpr std::byte divF32{0x95};

    static constexpr std::byte eqF64{0x61};
    static constexpr std::byte neF64{0x62};
    static constexpr std::byte ltF64{0x63};
    static constexpr std::byte gtF64{0x64};
    static constexpr std::byte leF64{0x65};
    static constexpr std::byte geF64{0x66};
    static constexpr std::byte addF64{0xA0};
    static constexpr std::byte subF64{0xA1};
    static constexpr std::byte mulF64{0xA2};
    static constexpr std::byte divF64{0xA3};
  };

  /// Byte encodings of types in wasm binaries
  /// These are defined in the wasm binary spec
  /// https://webassembly.github.io/spec/core/binary/types.html
  struct TypeEncoding {
    static constexpr std::byte i32{0x7F};
    static constexpr std::byte i64{0x7E};
    static constexpr std::byte f32{0x7D};
    static constexpr std::byte f64{0x7C};
    static constexpr std::byte v128{0x7B};
    static constexpr std::byte funcRef{0x70};
    static constexpr std::byte externRef{0x6F};
    static constexpr std::byte funcType{0x60};
    static constexpr std::byte emptyBlockType{0x40};
  };

  struct ImportType {
    static constexpr std::byte typeID{0x00};
    static constexpr std::byte tableType{0x01};
    static constexpr std::byte memType{0x02};
    static constexpr std::byte globalType{0x03};
  };

  struct LimitHeader {
    static constexpr std::byte lowLimitOnly{0x00};
    static constexpr std::byte bothLimits{0x01};
  };

  struct GlobalMutability {
    static constexpr std::byte isConst{0x00};
    static constexpr std::byte isMutable{0x01};
  };

  struct ExportType {
    static constexpr std::byte function{0x00};
    static constexpr std::byte table{0x01};
    static constexpr std::byte memory{0x02};
    static constexpr std::byte global{0x03};
  };

  static constexpr std::byte endByte{0x0B};
};

template <std::byte... Bytes>
struct ByteSequence{};

template <std::byte... Bytes1, std::byte... Bytes2>
constexpr ByteSequence<Bytes1..., Bytes2...>
operator+(ByteSequence<Bytes1...>, ByteSequence<Bytes2...>) {
  return {};
}

template <typename T, T... Values>
constexpr ByteSequence<std::byte{Values}...>
byteSeqFromIntSeq(std::integer_sequence<T, Values...>) {
  return {};
}

constexpr auto allOpCodes =
    byteSeqFromIntSeq(std::make_integer_sequence<int, 256>());

constexpr ByteSequence<
    WasmEncodings::TypeEncoding::i32, WasmEncodings::TypeEncoding::i64,
    WasmEncodings::TypeEncoding::f32, WasmEncodings::TypeEncoding::f64,
    WasmEncodings::TypeEncoding::v128>
    valueTypesEncodings{};

template<std::byte... allowedFlags>
constexpr bool isValueOneOf(std::byte value, ByteSequence<allowedFlags...> = {}) {
  return  ((value == allowedFlags) | ... | false);
}

template<std::byte... flags>
constexpr bool isNotIn(std::byte value, ByteSequence<flags...> = {}) {
  return !isValueOneOf<flags...>(value);
}

struct GlobalTypeRecord {
  Type type;
  bool isMutable;
};

struct TypeIdxRecord {
  size_t id;
};

struct SymbolRefContainer {
  FlatSymbolRefAttr symbol;
};

struct GlobalSymbolRefContainer : SymbolRefContainer {
  Type globalType;
};

struct FunctionSymbolRefContainer : SymbolRefContainer {
  FunctionType functionType;
};

using ImportDesc = std::variant<TypeIdxRecord, TableType, LimitType, GlobalTypeRecord>;

using parsed_inst_t = llvm::FailureOr<llvm::SmallVector<Value>>;

struct EmptyBlockMarker{};
using BlockTypeParseResult = std::variant<EmptyBlockMarker, TypeIdxRecord, Type>;

struct WasmModuleSymbolTables {
  llvm::SmallVector<FunctionSymbolRefContainer> funcSymbols;
  llvm::SmallVector<GlobalSymbolRefContainer> globalSymbols;
  llvm::SmallVector<SymbolRefContainer> memSymbols;
  llvm::SmallVector<SymbolRefContainer> tableSymbols;
  llvm::SmallVector<FunctionType> moduleFuncTypes;

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
};

class ParserHead;

/// Wrapper around SmallVector to only allow access as push and pop on the
/// stack. Makes sure that there are no "free accesses" on the stack to preserve
/// its state.
class ValueStack {
public:
  bool empty() const { return values.empty(); }

  size_t size() const { return values.size(); }

  /// Pops values from the stack because they are being used in an operation.
  /// @param operandTypes The list of expected types of the operation, used
  ///   to know how many values to pop and check if the types match the
  ///   expectation.
  /// @param opLoc Location of the caller, used to report accurately the
  /// location
  ///   if an error occurs.
  /// @return Failure or the vector of popped values.
  llvm::FailureOr<llvm::SmallVector<Value>> popOperands(TypeRange operandTypes,
                                                        Location *opLoc);

  /// Push the results of an operation to the stack so they can be used in a
  /// following operation.
  /// @param results The list of results of the operation
  /// @param opLoc Location of the caller, used to report accurately the
  /// location
  ///   if an error occurs.
  LogicalResult pushResults(ValueRange results, Location *opLoc);

  void addFrame() {
    frameIndexes.push_back(values.size());
    LLVM_DEBUG(llvm::dbgs() << "Adding a new frame context to ValueStack");
  }

  void dropFrame() {
    assert(!frameIndexes.empty() && "Trying to drop a frame from empty context");
    auto newSize = frameIndexes.pop_back_val();
    values.truncate(newSize);
  }

#if !defined(NDEBUG) || defined(LLVM_ENABLE_DUMP)
  /// A simple dump function for debugging.
  /// Writes output to llvm::dbgs().
  LLVM_DUMP_METHOD void dump() const;
#endif

private:
  llvm::SmallVector<Value> values;
  llvm::SmallVector<size_t> frameIndexes;
};

using local_val_t = TypedValue<MemRefType>;

class ExpressionParser {
public:
  using locals_t = llvm::SmallVector<local_val_t>;
  ExpressionParser(ParserHead &parser, WasmModuleSymbolTables const &symbols,
                   llvm::ArrayRef<local_val_t> initLocal)
      : parser{parser}, symbols{symbols}, locals{initLocal} {}

private:
  template <std::byte opCode>
  inline parsed_inst_t parseSpecificInstruction(OpBuilder &builder);

  template <typename valueT>
  parsed_inst_t
  parseConstInst(OpBuilder &builder,
                 std::enable_if_t<std::is_arithmetic_v<valueT>> * = nullptr);

  /// Construct an operation with \p numOperands operands and a single result.
  /// Each operand must have the same type. Suitable for e.g. binops, unary
  /// ops, etc.
  ///
  /// \p opcode - The WASM opcode to build.
  /// \p valueType - The operand and result type for the built instruction.
  /// \p numOperands - The number of operands for the built operation.
  ///
  /// \returns The parsed instruction, or failure.
  template <typename opcode, typename valueType, unsigned int numOperands>
  inline parsed_inst_t
  buildNumericOp(OpBuilder &builder,
                 std::enable_if_t<std::is_arithmetic_v<valueType>> * = nullptr);

  /// This function generates a dispatch tree to associate an opcode with a
  /// parser. Parsers are registered by specialising the
  /// `parseSpecificInstruction` function for the op code to handle.
  ///
  /// The dispatcher is generated by recursively creating all possible patterns
  /// for an opcode and calling the relevant parser on the leaf.
  ///
  /// @tparam patternBitSize is the first bit for which the pattern is not fixed
  ///
  /// @tparam highBitPattern is the fixed pattern that this instance handles for
  /// the 8-patternBitSize bits
  template <size_t patternBitSize = 0, std::byte highBitPattern = std::byte{0}>
  inline parsed_inst_t dispatchToInstParser(std::byte opCode,
                                            OpBuilder &builder) {
    static_assert(patternBitSize <= 8,
                  "PatternBitSize is outside of range of opcode space! "
                  "(expected at most 8 bits)");
    if constexpr (patternBitSize < 8) {
      constexpr std::byte bitSelect{1 << (7 - patternBitSize)};
      constexpr std::byte nextHighBitPatternStem = highBitPattern << 1;
      constexpr size_t nextPatternBitSize = patternBitSize + 1;
      if ((opCode & bitSelect) != std::byte{0})
        return dispatchToInstParser < nextPatternBitSize,
               nextHighBitPatternStem | std::byte{1} > (opCode, builder);
      return dispatchToInstParser<nextPatternBitSize, nextHighBitPatternStem>(
          opCode, builder);
    } else {
      return parseSpecificInstruction<highBitPattern>(builder);
    }
  }


  struct NestingContext {
    NestingContext(ExpressionParser& parser):parser{parser}{
      parser.addNestingContextLevel();
    }
    NestingContext(NestingContext&& other):parser{other.parser}{
      other.shouldDropOnDestruct = false;
    }
    NestingContext(NestingContext const &) = delete;
    ~NestingContext() {
      if (shouldDropOnDestruct)
        parser.dropNestingContextLevel();
    }
    ExpressionParser& parser;
    bool shouldDropOnDestruct = true;
  };

  void addNestingContextLevel() {
    valueStack.addFrame();
  }

  void dropNestingContextLevel() {
    // Should always succeed as we are droping the frame that was previously created.
    valueStack.dropFrame();
  }

  llvm::FailureOr<FunctionType> getFuncTypeFor(OpBuilder & builder, EmptyBlockMarker) {
    return builder.getFunctionType({}, {});
  }

  llvm::FailureOr<FunctionType> getFuncTypeFor(OpBuilder & builder, TypeIdxRecord type) {
    if (type.id > symbols.moduleFuncTypes.size())
      return emitError(*currentOpLoc, "Type index references nonexistent type: ")
             << type.id << ". Only " << symbols.moduleFuncTypes.size()
             << " types are registered.";
    return symbols.moduleFuncTypes[type.id];
  }

  llvm::FailureOr<FunctionType> getFuncTypeFor(OpBuilder & builder, Type valType) {
    return builder.getFunctionType({}, {valType});
  }

public:
  parsed_inst_t parse(OpBuilder &builder,
                      std::byte endByte = WasmEncodings::endByte);

  NestingContext addNesting() {
    return NestingContext{*this};
  }

  llvm::FailureOr<llvm::SmallVector<Value>>
  popOperands(TypeRange operandTypes) {
    return valueStack.popOperands(operandTypes, &currentOpLoc.value());
  }

  LogicalResult pushResults(ValueRange results) {
    return valueStack.pushResults(results, &currentOpLoc.value());
  }

  /// The local.set and local.tee operations behave similarly and only differ
  /// on their return value. This function factorizes the behavior of the two
  /// operations in one place.
  template<typename OpToCreate>
  parsed_inst_t parseSetOrTee(OpBuilder &);

private:
  std::optional<Location> currentOpLoc;
  ParserHead &parser;
  WasmModuleSymbolTables const &symbols;
  locals_t locals;
  ValueStack valueStack;
};

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
    LLVM_DEBUG(llvm::dbgs() << "Consume " << nBytes << " bytes\n");
    LLVM_DEBUG(llvm::dbgs() << "  Bytes remaining: " << size() << "\n");
    LLVM_DEBUG(llvm::dbgs() << "  Current offset: " << offset << "\n");
    if (nBytes > size())
      return emitError(getLocation(), "trying to extract ")
             << nBytes << "bytes when only " << size() << "are avilables";

    auto res = head.slice(offset, offset + nBytes);
    offset += nBytes;
    LLVM_DEBUG(llvm::dbgs()
               << "  Updated offset (+" << nBytes << "): " << offset << "\n");
    return res;
  }

  llvm::FailureOr<std::byte> consumeByte() {
    auto res = consumeNBytes(1);
    if (failed(res))
      return failure();
    return std::byte{*res->bytes_begin()};
  }

  template <typename T>
  llvm::FailureOr<T> parseLiteral();

  llvm::FailureOr<uint32_t> parseVectorSize();

private:
  // TODO: This is equivalent to parseLiteral<uint32_t> and could be removed
  // if parseLiteral specialisation were moved here, but default GCC on Ubuntu
  // 22.04 has bug with template specialisation in class declaration
  inline llvm::FailureOr<uint32_t> parseUI32();
  inline llvm::FailureOr<int64_t> parseI64();

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
    if (std::to_integer<unsigned>(*id) > highestWasmSectionID)
      return emitError(getLocation(), "Invalid section ID: ")
             << static_cast<int>(*id);
    return static_cast<WasmSectionType>(*id);
  }

  llvm::FailureOr<LimitType> parseLimit(MLIRContext* ctx) {
    using WasmLimits = WasmEncodings::LimitHeader;
    auto limitLocation = getLocation();
    auto limitHeader = consumeByte();
    if (failed(limitHeader))
      return failure();

    if (isNotIn<WasmLimits::bothLimits, WasmLimits::lowLimitOnly>(*limitHeader))
      return emitError(limitLocation, "Invalid limit header: ")
             << static_cast<int>(*limitHeader);
    auto minParse = parseUI32();
    if (failed(minParse))
      return failure();
    std::optional<uint32_t> max{std::nullopt};
    if (*limitHeader == WasmLimits::bothLimits) {
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
    using WasmGlobalMut = WasmEncodings::GlobalMutability;
    auto typeParsed = parseValueType(ctx);
    if (failed(typeParsed))
      return failure();
    auto mutLoc = getLocation();
    auto mutSpec = consumeByte();
    if (failed(mutSpec))
      return failure();
    if (isNotIn<WasmGlobalMut::isConst, WasmGlobalMut::isMutable>(*mutSpec))
      return emitError(mutLoc, "Invalid global mutability specifier: ")
             << static_cast<int>(*mutSpec);
    return GlobalTypeRecord{*typeParsed, *mutSpec == WasmGlobalMut::isMutable};
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
             << std::to_integer<unsigned>(WasmEncodings::TypeEncoding::funcType)
             << " got " << std::to_integer<unsigned>(*funcTypeHeader);
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

  parsed_inst_t parseExpression(OpBuilder &builder,
                                WasmModuleSymbolTables const &symbols,
                                llvm::ArrayRef<local_val_t> locals = {}) {
    auto eParser = ExpressionParser{*this, symbols, locals};
    return eParser.parse(builder);
  }

  llvm::LogicalResult parseCodeFor(FuncOp func,
                                   WasmModuleSymbolTables const &symbols) {
    llvm::SmallVector<local_val_t> locals{};
    // Populating locals with function argument
    auto &block = func.getBody().front();
    // Delete temporary return argument which was only created for IR validity
    assert(func.getBody().getBlocks().size() == 1 &&
           "Function should only have its default created block at this point");
    assert(block.getOperations().size() == 1 &&
           "Only the placeholder return op should be present at this point");
    auto returnOp = cast<ReturnOp>(&block.back());
    assert(returnOp);

    auto codeSizeInBytes = parseUI32();
    if (failed(codeSizeInBytes))
      return failure();
    auto codeContent = consumeNBytes(*codeSizeInBytes);
    if (failed(codeContent))
      return failure();
    auto name = StringAttr::get(func->getContext(),
                                locName.str() + "::" + func.getSymName());
    auto cParser = ParserHead{*codeContent, name};
    auto localVecSize = cParser.parseVectorSize();
    if (failed(localVecSize))
      return failure();
    OpBuilder builder{&func.getBody().front().back()};
    for (auto arg : block.getArguments())
      locals.push_back(
          builder.create<LocalFromArgOp>(func->getLoc(), arg).getResult());
    // Declare the local ops
    auto nVarVec = *localVecSize;
    for (size_t i = 0; i < nVarVec; ++i) {
      auto varLoc = cParser.getLocation();
      auto nSubVar = cParser.parseUI32();
      if (failed(nSubVar))
        return failure();
      auto varT = cParser.parseValueType(func->getContext());
      if (failed(varT))
        return failure();
      for (size_t j = 0; j < *nSubVar; ++j) {
        auto local = builder.create<LocalOp>(varLoc, *varT);
        locals.push_back(local.getResult());
      }
    }
    auto res = cParser.parseExpression(builder, symbols, locals);
    if (failed(res))
      return failure();
    if (!cParser.end())
      return emitError(cParser.getLocation(),
                "Unparsed garbage remaining at end of code block");
    builder.create<ReturnOp>(func->getLoc(), *res);
    returnOp->erase();
    return success();
  }

  llvm::FailureOr<BlockTypeParseResult> parseBlockType(MLIRContext *ctx) {
    auto loc = getLocation();
    auto blockIndicator = peek();
    if (failed(blockIndicator))
      return failure();
    if (*blockIndicator == WasmEncodings::TypeEncoding::emptyBlockType) {
      offset += 1;
      return {EmptyBlockMarker{}};
    }
    if (isValueOneOf(*blockIndicator, valueTypesEncodings))
      return parseValueType(ctx);
    /// Block type idx is a 32 bit positive integer encoded as a 33 bit signed
    /// value
    auto typeIdx = parseI64();
    if (failed(typeIdx))
      return failure();
    if (*typeIdx < 0 || *typeIdx > std::numeric_limits<uint32_t>::max())
      return emitError(loc, "type ID should be representable with an unsigned "
                            "32 bits integer. Got ")
             << *typeIdx;
    return {TypeIdxRecord{static_cast<uint32_t>(*typeIdx)}};
  }

  bool end() const { return curHead().empty(); }

  ParserHead copy() const {
    return *this;
  }

private:
  llvm::StringRef curHead() const { return head.drop_front(offset); }

  llvm::FailureOr<std::byte> peek() const {
    if (end())
      return emitError(
          getLocation(),
          "trying to peek at next byte, but input stream is empty");
    return static_cast<std::byte>(curHead().front());
  }

  size_t size() const { return head.size() - offset; }

  llvm::StringRef head;
  StringAttr locName;
  unsigned anchorOffset{0};
  unsigned offset{0};
};

template <>
llvm::FailureOr<float> ParserHead::parseLiteral<float>() {
  auto bytes = consumeNBytes(4);
  if (failed(bytes))
    return failure();
  float result;
  std::memcpy(&result, bytes->bytes_begin(), 4);
  return result;
}

template <>
llvm::FailureOr<double> ParserHead::parseLiteral<double>() {
  auto bytes = consumeNBytes(8);
  if (failed(bytes))
    return failure();
  double result;
  std::memcpy(&result, bytes->bytes_begin(), 8);
  return result;
}

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

template <>
llvm::FailureOr<int32_t> ParserHead::parseLiteral<int32_t>() {
  char const *error = nullptr;
  int32_t res{0};
  unsigned encodingSize{0};
  auto src = curHead();
  auto decoded = llvm::decodeSLEB128(src.bytes_begin(), &encodingSize,
                                     src.bytes_end(), &error);
  if (error)
    return emitError(getLocation(), error);
  if (std::isgreater(decoded, std::numeric_limits<int32_t>::max()) ||
      std::isgreater(std::numeric_limits<int32_t>::min(), decoded))
    return emitError(getLocation()) << "literal does not fit on 32 bits";

  res = static_cast<int32_t>(decoded);
  offset += encodingSize;
  return res;
}

template <>
llvm::FailureOr<int64_t> ParserHead::parseLiteral<int64_t>() {
  char const *error = nullptr;
  unsigned encodingSize{0};
  auto src = curHead();
  auto res = llvm::decodeSLEB128(src.bytes_begin(), &encodingSize,
                                 src.bytes_end(), &error);
  if (error)
    return emitError(getLocation(), error);

  offset += encodingSize;
  return res;
}

llvm::FailureOr<uint32_t> ParserHead::parseVectorSize() {
  return parseLiteral<uint32_t>();
}

inline llvm::FailureOr<uint32_t> ParserHead::parseUI32() {
  return parseLiteral<uint32_t>();
}

inline llvm::FailureOr<int64_t> ParserHead::parseI64() {
  return parseLiteral<int64_t>();
}

template <std::byte opCode>
inline parsed_inst_t ExpressionParser::parseSpecificInstruction(OpBuilder &) {
  return emitError(*currentOpLoc, "Unknown instruction opcode: ")
         << static_cast<int>(opCode);
}

#if !defined(NDEBUG) || defined(LLVM_ENABLE_DUMP)
void ValueStack::dump() const {
  llvm::dbgs() << "================= Wasm ValueStack =======================\n";
  llvm::dbgs() << "size: " << size() << "\n";
  llvm::dbgs() << "nbFrames: " << frameIndexes.size() << '\n';
  llvm::dbgs() << "<Top>"
               << "\n";
  // Stack is pushed to via push_back. Therefore the top of the stack is the
  // end of the vector. Iterate in reverse so that the first thing we print
  // is the top of the stack.
  auto indexGetter = [this](){
    size_t idx = frameIndexes.size();
    return [this, idx]() mutable-> std::optional<std::pair<size_t, size_t>> {
      llvm::dbgs() << "IDX: " << idx << '\n';
      if (idx == 0)
        return std::nullopt;
      auto frameId = idx - 1;
      auto frameLimit = frameIndexes[frameId];
      idx -= 1;
      return {{frameId, frameLimit}};
    };
  };
  auto getNextFrameIndex = indexGetter();
  auto nextFrameIdx = getNextFrameIndex();
  for (size_t idx = 0 ; idx < size() ;) {
    size_t actualIdx = size() - 1 - idx;
    while (nextFrameIdx && (nextFrameIdx->second > actualIdx)) {
      llvm::dbgs() << "  --------------- Frame ("<< nextFrameIdx->first <<")\n";
      nextFrameIdx = getNextFrameIndex();
    }
    llvm::dbgs() << "  ";
    values[actualIdx].dump();
  }
  while (nextFrameIdx) {
    llvm::dbgs() << "  --------------- Frame ("<< nextFrameIdx->first <<")\n";
      nextFrameIdx = getNextFrameIndex();
  }
  llvm::dbgs() << "<Bottom>"
               << "\n";
  llvm::dbgs() << "=========================================================\n";
}
#endif

parsed_inst_t ValueStack::popOperands(TypeRange operandTypes, Location *opLoc) {
  LLVM_DEBUG(llvm::dbgs() << "Popping from ValueStack\n");
  LLVM_DEBUG(llvm::dbgs() << "  Elements(s) to pop: " << operandTypes.size()
                          << "\n");
  LLVM_DEBUG(llvm::dbgs() << "  Current stack size: " << values.size() << "\n");
  if (operandTypes.size() > values.size())
    return emitError(*opLoc,
                     "Stack doesn't contain enough values. Trying to get ")
           << operandTypes.size() << " operands on a stack containing only "
           << values.size() << " values.";
  size_t stackIdxOffset = values.size() - operandTypes.size();
  llvm::SmallVector<Value> res{};
  res.reserve(operandTypes.size());
  for (size_t i{0}; i < operandTypes.size(); ++i) {
    Value operand = values[i + stackIdxOffset];
    Type stackType = operand.getType();
    if (stackType != operandTypes[i])
      return emitError(*opLoc,
                       "Invalid operand type on stack. Expecting ")
             << operandTypes[i] << ", value on stack is of type " << stackType
             << ".";
    LLVM_DEBUG(llvm::dbgs() << "    POP: " << operand << "\n");
    res.push_back(operand);
  }
  values.resize(values.size() - operandTypes.size());
  LLVM_DEBUG(llvm::dbgs() << "  Updated stack size: " << values.size() << "\n");
  return res;
}

LogicalResult ValueStack::pushResults(ValueRange results, Location *opLoc) {
  LLVM_DEBUG(llvm::dbgs() << "Pushing to ValueStack\n");
  LLVM_DEBUG(llvm::dbgs() << "  Elements(s) to push: " << results.size()
                          << "\n");
  LLVM_DEBUG(llvm::dbgs() << "  Current stack size: " << values.size() << "\n");
  for (auto val : results) {
    if (!isWasmValueType(val.getType()))
      return emitError(*opLoc, "Invalid value type on stack: ")
             << val.getType();
    LLVM_DEBUG(llvm::dbgs() << "    PUSH: " << val << "\n");
    values.push_back(val);
  }

  LLVM_DEBUG(llvm::dbgs() << "  Updated stack size: " << values.size() << "\n");
  return success();
}

parsed_inst_t ExpressionParser::parse(OpBuilder &builder, std::byte endByte) {
  llvm::SmallVector<Value> res;
  for (;;) {
    currentOpLoc = parser.getLocation();
    auto opCode = parser.consumeByte();
    if (failed(opCode))
      return failure();
    if (*opCode == endByte)
      return res;
    parsed_inst_t resParsed;
    resParsed = dispatchToInstParser(*opCode, builder);
    if (failed(resParsed))
      return failure();
    std::swap(res, *resParsed);
    if (failed(pushResults(res)))
      return failure();
  }
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::block>(
    OpBuilder &builder) {
  auto opLoc = currentOpLoc;
  auto blockType = parser.parseBlockType(builder.getContext());
  if (failed(blockType))
    return failure();
  auto funcType = std::visit(
      [this, &builder](auto parseResult) {
        return getFuncTypeFor(builder, parseResult);
      },
      *blockType);
  if (failed(funcType))
    return failure();

  LLVM_DEBUG(llvm::dbgs() << "Parsing a block of type " << *funcType);
  auto inputTypes = funcType->getInputs();
  auto inputOps = popOperands(inputTypes);
  if (failed(inputOps))
    return failure();

  auto resTypes = funcType->getResults();
  auto blockOp = builder.create<BlockOp>(*currentOpLoc, resTypes, *inputOps);
  auto *blockBody = blockOp.createBlock();
  auto sip = builder.saveInsertionPoint();
  builder.setInsertionPointToStart(blockBody);
  {
    auto nC = addNesting();
    if (failed(pushResults(blockBody->getArguments())))
      return failure();
    auto bodyParsingRes = parse(builder);
    if (failed(bodyParsingRes))
      return failure();
    auto resVals = popOperands(resTypes);
    builder.create<ReturnOp>(*opLoc, *resVals);
  }
  builder.restoreInsertionPoint(sip);
  LLVM_DEBUG(llvm::dbgs() << "End of parsing of a block of type " << *funcType);
  return {blockOp->getResults()};
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::call>(
    OpBuilder &builder) {
  auto loc = *currentOpLoc;
  auto funcIdx = parser.parseLiteral<uint32_t>();
  if (failed(funcIdx))
    return failure();
  if (*funcIdx >= symbols.funcSymbols.size())
    return emitError(loc, "Invalid function index: ") << *funcIdx;
  auto callee = symbols.funcSymbols[*funcIdx];
  llvm::ArrayRef<Type> inTypes = callee.functionType.getInputs();
  llvm::ArrayRef<Type> resTypes = callee.functionType.getResults();
  parsed_inst_t inOperands = popOperands(inTypes);
  if (failed(inOperands))
    return failure();
  auto callOp = builder.create<FuncCallOp>(
      loc, resTypes, callee.symbol, *inOperands);
  return {callOp.getResults()};
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::localGet>(
    OpBuilder &builder) {
  auto id = parser.parseLiteral<uint32_t>();
  auto instLoc = *currentOpLoc;
  if (failed(id))
    return failure();
  if (*id >= locals.size())
    return emitError(instLoc, "Invalid local index. Function has ")
           << locals.size() << " accessible locals, received index " << *id;
  return {{builder.create<LocalGetOp>(instLoc, locals[*id]).getResult()}};
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::globalGet>(
    OpBuilder &builder) {
  auto id = parser.parseLiteral<uint32_t>();
  auto instLoc = *currentOpLoc;
  if (failed(id))
    return failure();
  if (*id >= symbols.globalSymbols.size())
    return emitError(instLoc, "Invalid global index. Function has ")
           << symbols.globalSymbols.size() << " accessible globals, received index " << *id;
  auto globalVar = symbols.globalSymbols[*id];
  auto globalOp = builder.create<GlobalGetOp>(instLoc, globalVar.globalType, globalVar.symbol);

  return {{globalOp.getResult()}};
}

template <typename OpToCreate>
parsed_inst_t ExpressionParser::parseSetOrTee(OpBuilder &builder) {
  auto id = parser.parseLiteral<uint32_t>();
  if (failed(id))
    return failure();
  if (*id >= locals.size())
    return emitError(*currentOpLoc, "Invalid local index. Function has ")
           << locals.size() << " accessible locals, received index " << *id;
  if (valueStack.empty())
    return emitError(
        *currentOpLoc,
        "Invalid stack access, trying to access a value on an empty stack.");

  parsed_inst_t poppedOp = popOperands(locals[*id].getType().getElementType());
  if (failed(poppedOp))
    return failure();
  return {
      builder.create<OpToCreate>(*currentOpLoc, locals[*id], poppedOp->front())
          ->getResults()};
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::localSet>(
    OpBuilder &builder) {
  return parseSetOrTee<LocalSetOp>(builder);
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::localTee>(
    OpBuilder & builder) {
  return parseSetOrTee<LocalTeeOp>(builder);
}

template <typename T>
inline Type buildLiteralType(OpBuilder &);

template <>
inline Type buildLiteralType<int32_t>(OpBuilder &builder) {
  return builder.getI32Type();
}

template <>
inline Type buildLiteralType<int64_t>(OpBuilder &builder) {
  return builder.getI64Type();
}

template <>
inline Type buildLiteralType<float>(OpBuilder &builder) {
  return builder.getF32Type();
}

template <>
inline Type buildLiteralType<double>(OpBuilder &builder) {
  return builder.getF64Type();
}

template<typename ValT, typename E = std::enable_if_t<std::is_arithmetic_v<ValT>>>
struct AttrHolder;

template <typename ValT>
struct AttrHolder<ValT, std::enable_if_t<std::is_integral_v<ValT>>> {
  using type = IntegerAttr;
};

template <typename ValT>
struct AttrHolder<ValT, std::enable_if_t<std::is_floating_point_v<ValT>>> {
  using type = FloatAttr;
};

template<typename ValT>
using attr_holder_t = typename AttrHolder<ValT>::type;

template <typename ValT,
          typename EnableT = std::enable_if_t<std::is_arithmetic_v<ValT>>>
attr_holder_t<ValT> buildLiteralAttr(OpBuilder &builder, ValT val) {
  return attr_holder_t<ValT>::get(buildLiteralType<ValT>(builder), val);
}

template <typename valueT>
parsed_inst_t ExpressionParser::parseConstInst(
    OpBuilder &builder, std::enable_if_t<std::is_arithmetic_v<valueT>> *) {
  auto parsedConstant = parser.parseLiteral<valueT>();
  if (failed(parsedConstant))
    return failure();
  auto constOp = builder.create<ConstOp>(
      *currentOpLoc, buildLiteralAttr<valueT>(builder, *parsedConstant));
  return {{constOp.getResult()}};
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::constI32>(
    OpBuilder &builder) {
  return parseConstInst<int32_t>(builder);
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::constI64>(
    OpBuilder &builder) {
  return parseConstInst<int64_t>(builder);
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::constFP32>(
    OpBuilder &builder) {
  return parseConstInst<float>(builder);
}

template <>
inline parsed_inst_t
ExpressionParser::parseSpecificInstruction<WasmEncodings::OpCode::constFP64>(
    OpBuilder &builder) {
  return parseConstInst<double>(builder);
}

template <typename opcode, typename valueType, unsigned int numOperands>
inline parsed_inst_t ExpressionParser::buildNumericOp(
    OpBuilder &builder, std::enable_if_t<std::is_arithmetic_v<valueType>> *) {
  auto ty = buildLiteralType<valueType>(builder);
  LLVM_DEBUG(llvm::dbgs() << "*** buildNumericOp: numOperands = " << numOperands
                          << ", type = " << ty << " ***\n");
  auto tysToPop = llvm::SmallVector<Type, numOperands>();
  tysToPop.resize(numOperands);
  std::fill(tysToPop.begin(), tysToPop.end(), ty);
  auto operands = popOperands(tysToPop);
  if (failed(operands))
    return failure();
  auto op = builder.create<opcode>(*currentOpLoc, *operands).getResult();
#ifndef NDEBUG
  llvm::dbgs() << "Built: ";
  op.dump();
#endif
  return {{op}};
}

#define ImplementNumericalOpPat(OP_NAME, N_ARGS, PREFIX, SUFFIX, TYPE)         \
    template <>                                                                \
    inline parsed_inst_t ExpressionParser::parseSpecificInstruction<           \
        WasmEncodings::OpCode::PREFIX##SUFFIX>(OpBuilder & builder) {          \
      return buildNumericOp<OP_NAME, TYPE, N_ARGS>(builder);                   \
    }

// Ops that exists for all numerical types

#define ImplementNumericalBinOpIntFP(OP_NAME, PREFIX)                          \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, I32, int32_t)                  \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, I64, int64_t)                  \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, F32, float)                    \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, F64, double)

ImplementNumericalBinOpIntFP(AddOp, add)
ImplementNumericalBinOpIntFP(MulOp, mul)
ImplementNumericalBinOpIntFP(SubOp, sub)
ImplementNumericalBinOpIntFP(EqOp, eq)
ImplementNumericalBinOpIntFP(NeOp, ne)

#undef ImplementNumericalBinOpIntFP

// Ops that exists for integer types

#define ImplementNumericalBinOpInt(OP_NAME, PREFIX)                                \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, I32, int32_t)                      \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, I64, int64_t)

ImplementNumericalBinOpInt(AndOp, and)
ImplementNumericalBinOpInt(DivSIOp, divS)
ImplementNumericalBinOpInt(DivUIOp, divU)
ImplementNumericalBinOpInt(OrOp, or)
ImplementNumericalBinOpInt(RemSIOp, remS)
ImplementNumericalBinOpInt(RemUIOp, remU)
ImplementNumericalBinOpInt(RotlOp, rotl)
ImplementNumericalBinOpInt(RotrOp, rotr)
ImplementNumericalBinOpInt(ShLOp, shl)
ImplementNumericalBinOpInt(ShRSOp, shr_s)
ImplementNumericalBinOpInt(ShRUOp, shr_u)
ImplementNumericalBinOpInt(XOrOp, xor)
ImplementNumericalBinOpInt(LtSIOp, ltS)
ImplementNumericalBinOpInt(LeSIOp, leS)
ImplementNumericalBinOpInt(LtUIOp, ltU)
ImplementNumericalBinOpInt(LeUIOp, leU)
ImplementNumericalBinOpInt(GtSIOp, gtS)
ImplementNumericalBinOpInt(GeSIOp, geS)
ImplementNumericalBinOpInt(GtUIOp, gtU)
ImplementNumericalBinOpInt(GeUIOp, geU)

#undef ImplementNumericalBinOpInt

#define ImplementNumericalBinOpFP(OP_NAME, PREFIX)                             \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, F32, float)                    \
    ImplementNumericalOpPat(OP_NAME, 2, PREFIX, F64, double)

ImplementNumericalBinOpFP(DivOp, div)
ImplementNumericalBinOpFP(LtOp, lt)
ImplementNumericalBinOpFP(LeOp, le)
ImplementNumericalBinOpFP(GtOp, gt)
ImplementNumericalBinOpFP(GeOp, ge)

#undef ImplementNumericalBinOpFP

#undef ImplementNumericalOpPat

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

  template <WasmSectionType>
  LogicalResult parseSectionItem(ParserHead &, size_t);

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
    LLVM_DEBUG(llvm::dbgs() << "Starting to parse " << nElems
                            << " items for section " << secName << ".\n");
    for (size_t i = 0; i < nElems; ++i) {
      if (failed(parseSectionItem<section>(ph, i)))
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
    if (tid.id >= symbols.moduleFuncTypes.size())
      return emitError(loc, "Invalid type id: ")
             << tid.id << ". Only " << symbols.moduleFuncTypes.size()
             << " type registration.";
    auto type = symbols.moduleFuncTypes[tid.id];
    auto symbol = symbols.getNewFuncSymbolName();
    auto funcOp = builder.create<FuncImportOp>(
        loc, symbol, moduleName, importName, type);
    symbols.funcSymbols.push_back({{FlatSymbolRefAttr::get(funcOp)}, type});
    return funcOp.verify();
  }

  /// Handles the registration of a memory import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName, LimitType limitType) {
    auto symbol = symbols.getNewMemorySymbolName();
    auto memOp = builder.create<MemImportOp>(loc, symbol, moduleName,
                                             importName, limitType);
    symbols.memSymbols.push_back({FlatSymbolRefAttr::get(memOp)});
    return memOp.verify();
  }

  /// Handles the registration of a table import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName, TableType tableType) {
    auto symbol = symbols.getNewTableSymbolName();
    auto tableOp = builder.create<TableImportOp>(loc, symbol, moduleName,
                                                 importName, tableType);
    symbols.tableSymbols.push_back({FlatSymbolRefAttr::get(tableOp)});
    return tableOp.verify();
  }

  /// Handles the registration of a global variable import
  LogicalResult visitImport(Location loc, llvm::StringRef moduleName,
                            llvm::StringRef importName,
                            GlobalTypeRecord globalType) {
    auto symbol = symbols.getNewGlobalSymbolName();
    auto giOp =
        builder.create<GlobalImportOp>(loc, symbol, moduleName, importName,
                                       globalType.type, globalType.isMutable);
    symbols.globalSymbols.push_back({{FlatSymbolRefAttr::get(giOp)}, giOp.getType()});
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

    firstInternalFuncID = symbols.funcSymbols.size();

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

    auto parsingCode = parseSection<WasmSectionType::CODE>();
    if (failed(parsingCode))
      return;

    auto parsingExports = parseSection<WasmSectionType::EXPORT>();
    if (failed(parsingExports))
      return;

    // Copy over sizes of containers into statistics.
    numFunctionSectionItems = symbols.funcSymbols.size();
    numGlobalSectionItems = symbols.globalSymbols.size();
    numMemorySectionItems = symbols.memSymbols.size();
    numTableSectionItems = symbols.tableSymbols.size();
  }

  ModuleOp getModule() { return mOp; }

private:
  mlir::StringAttr srcName;
  OpBuilder builder;
  WasmModuleSymbolTables symbols;
  MLIRContext *ctx;
  ModuleOp mOp;
  SectionRegistry registry;
  size_t firstInternalFuncID{0};
};

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::IMPORT>(ParserHead &ph, size_t) {
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
WasmBinaryParser::parseSectionItem<WasmSectionType::EXPORT>(ParserHead &ph,
                                                            size_t) {
  auto exportLoc = ph.getLocation();

  auto exportName = ph.parseName();
  if (failed(exportName))
    return failure();

  auto opcode = ph.consumeByte();
  if (failed(opcode))
    return failure();

  auto idx = ph.parseLiteral<uint32_t>();
  if (failed(idx))
    return failure();

  using SymbolRefDesc =
      std::variant<llvm::SmallVector<SymbolRefContainer>,
                   llvm::SmallVector<GlobalSymbolRefContainer>,
                   llvm::SmallVector<FunctionSymbolRefContainer>>;

  SymbolRefDesc currentSymbolList;
  std::string symbolType = "";
  switch (*opcode) {
  case WasmEncodings::ExportType::function:
    symbolType = "function";
    currentSymbolList = symbols.funcSymbols;
    break;
  case WasmEncodings::ExportType::table:
    symbolType = "table";
    currentSymbolList = symbols.tableSymbols;
    break;
  case WasmEncodings::ExportType::memory:
    symbolType = "memory";
    currentSymbolList = symbols.memSymbols;
    break;
  case WasmEncodings::ExportType::global:
    symbolType = "global";
    currentSymbolList = symbols.globalSymbols;
    break;
  default:
    return emitError(exportLoc, "Invalid value for export type: ")
           << std::to_integer<unsigned>(*opcode);
  }

  auto currentSymbol = std::visit(
      [&](const auto &list) -> FailureOr<FlatSymbolRefAttr> {
        if (*idx > list.size()) {
          emitError(
              exportLoc,
              llvm::formatv(
                  "Trying to export {0} {1} which is undefined in this scope",
                  symbolType, *idx));
          return failure();
        }
        return list[*idx].symbol;
      },
      currentSymbolList);

  if (failed(currentSymbol))
    return failure();

  Operation *op = SymbolTable::lookupSymbolIn(mOp, *currentSymbol);
  SymbolTable::setSymbolVisibility(op, SymbolTable::Visibility::Public);
  auto symName = SymbolTable::getSymbolName(op);
  return SymbolTable{mOp}.rename(symName, *exportName);
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::TABLE>(ParserHead &ph, size_t) {
  auto opLocation = ph.getLocation();
  auto tableType = ph.parseTableType(ctx);
  if (failed(tableType))
    return failure();
  LLVM_DEBUG(llvm::dbgs() << "  Parsed table description: " << *tableType
                          << '\n');
  auto symbol = builder.getStringAttr(symbols.getNewTableSymbolName());
  auto tableOp = builder.create<TableOp>(opLocation, symbol.strref(), *tableType);
  symbols.tableSymbols.push_back({SymbolRefAttr::get(tableOp)});
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::FUNCTION>(ParserHead &ph,
                                                              size_t) {
  auto opLoc = ph.getLocation();
  auto typeIdxParsed = ph.parseLiteral<uint32_t>();
  if (failed(typeIdxParsed))
    return failure();
  auto typeIdx = *typeIdxParsed;
  if (typeIdx >= symbols.moduleFuncTypes.size())
    return emitError(getLocation(), "Invalid type index: ") << typeIdx;
  auto symbol = symbols.getNewFuncSymbolName();
  auto funcOp =
      builder.create<FuncOp>(opLoc, symbol, symbols.moduleFuncTypes[typeIdx]);
  auto *block = funcOp.addEntryBlock();
  auto ip = builder.saveInsertionPoint();
  builder.setInsertionPointToEnd(block);
  builder.create<ReturnOp>(opLoc);
  builder.restoreInsertionPoint(ip);
  symbols.funcSymbols.push_back(
      {{FlatSymbolRefAttr::get(funcOp.getSymNameAttr())},
       symbols.moduleFuncTypes[typeIdx]});
  return funcOp.verify();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::TYPE>(ParserHead &ph,
                                                          size_t) {
  auto funcType = ph.parseFunctionType(ctx);
  if (failed(funcType))
    return failure();
  LLVM_DEBUG(llvm::dbgs() << "Parsed function type " << *funcType << '\n');
  symbols.moduleFuncTypes.push_back(*funcType);
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::MEMORY>(ParserHead &ph, size_t) {
  auto opLocation = ph.getLocation();
  auto memory = ph.parseLimit(ctx);
  if (failed(memory))
    return failure();

  LLVM_DEBUG(llvm::dbgs() << "  Registering memory " << *memory << '\n');
  auto symbol = symbols.getNewMemorySymbolName();
  auto memOp = builder.create<MemOp>(opLocation, symbol, *memory);
  symbols.memSymbols.push_back({SymbolRefAttr::get(memOp)});
  return success();
}

template <>
LogicalResult
WasmBinaryParser::parseSectionItem<WasmSectionType::GLOBAL>(ParserHead &ph,
                                                            size_t) {
  auto globalLocation = ph.getLocation();
  auto globalTypeParsed = ph.parseGlobalType(ctx);
  if (failed(globalTypeParsed))
    return failure();

  auto globalType = *globalTypeParsed;
  auto symbol = builder.getStringAttr(symbols.getNewGlobalSymbolName());
  auto globalOp = builder.create<wasm::GlobalOp>(
      globalLocation, symbol, globalType.type, globalType.isMutable);
  symbols.globalSymbols.push_back(
      {{FlatSymbolRefAttr::get(globalOp)}, globalOp.getType()});
  auto ip = builder.saveInsertionPoint();
  auto *block = builder.createBlock(&globalOp.getInitializer());
  builder.setInsertionPointToStart(block);
  auto expr = ph.parseExpression(builder, symbols);
  if (failed(expr))
    return failure();
  if (block->empty())
    return emitError(globalLocation, "global with empty initializer");
  if (expr->size() != 1 && (*expr)[0].getType() != globalType.type)
    return emitError(
        globalLocation,
        "initializer result type does not match global declaration type");
  builder.create<ReturnOp>(globalLocation, *expr);
  builder.restoreInsertionPoint(ip);
  return success();
}

template <>
LogicalResult WasmBinaryParser::parseSectionItem<WasmSectionType::CODE>(
    ParserHead &ph, size_t innerFunctionId) {
  auto funcId = innerFunctionId + firstInternalFuncID;
  auto symRef = symbols.funcSymbols[funcId];
  auto funcOp =
      llvm::dyn_cast<FuncOp>(SymbolTable::lookupSymbolIn(mOp, symRef.symbol));
  assert(funcOp);
  if (failed(ph.parseCodeFor(funcOp, symbols)))
    return failure();
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
