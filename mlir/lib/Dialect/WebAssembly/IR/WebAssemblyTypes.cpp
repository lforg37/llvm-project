#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/Types.h"
#include "llvm/Support/LogicalResult.h"
#include <optional>
#include <sstream>

namespace mlir {
namespace wasm {
#include "mlir/Dialect/WebAssembly/IR/WebAssemblyTypeConstraints.cpp.inc"
}
}


using namespace mlir;
using namespace mlir::wasm;

Type wasm::LimitType::parse(::mlir::AsmParser &parser) {
  auto res = parser.parseLSquare();
  uint32_t minLimit{0};
  std::optional<uint32_t> maxLimit{std::nullopt};
  res = parser.parseInteger(minLimit);
  res = parser.parseColon();
  uint32_t maxValue{0};
  auto maxParseRes = parser.parseOptionalInteger(maxValue);
  if (maxParseRes.has_value() && (*maxParseRes).succeeded())
    maxLimit = maxValue;

  res = parser.parseRSquare();
  return LimitType::get(parser.getContext(), minLimit, maxLimit);
}

void wasm::LimitType::print(AsmPrinter & printer) const {
  std::stringstream ss;
  ss <<  '[' << getMin() << ':';
  auto maxLim = getMax();
  if (maxLim)
    ss << *maxLim;
  ss << ']';
  printer.printString(ss.str());
}
