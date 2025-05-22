//===- WasmToStandard.cpp - Convert wams to standard dialects ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements lowering of wasm operations to standard dialects ops.
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/WasmToStandard/WasmToStandard.h"


#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/WebAssembly/IR/WebAssembly.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/Transforms/Passes.h"
#include "llvm/Support/LogicalResult.h"

#include <optional>

namespace mlir {
#define GEN_PASS_DEF_CONVERTWASMTOSTANDARD
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::wasm;

namespace {

template <typename SourceOp, typename TargetIntOp, typename TargetFPOp>
struct BinaryIntFPOpConversionPattern : OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SourceOp srcOp, typename SourceOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type type = srcOp.getRhs().getType();
    if (type.isInteger()) {
      rewriter.replaceOpWithNewOp<TargetIntOp>(srcOp, srcOp->getResultTypes(),
                                               adaptor.getOperands());
      return success();
    }
    if (!type.isFloat())
      return failure();
    rewriter.replaceOpWithNewOp<TargetFPOp>(srcOp, srcOp->getResultTypes(),
                                            adaptor.getOperands());
    return success();
  }
};

using WasmAddOpConversion =
    BinaryIntFPOpConversionPattern<AddOp, arith::AddIOp, arith::AddFOp>;

template <typename SourceOp, typename TargetOp>
struct BinaryOpConversion : OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SourceOp srcOp, typename SourceOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<TargetOp>(srcOp, srcOp->getResultTypes(),
                                          adaptor.getOperands());
    return success();
  }
};

using WasmDivFPOpConversion = BinaryOpConversion<DivOp, arith::DivFOp>;
using WasmDivSIOpConversion = BinaryOpConversion<DivSIOp, arith::DivSIOp>;
using WasmDivUIOpConversion = BinaryOpConversion<DivUIOp, arith::DivUIOp>;
using WasmRemSIOpConversion = BinaryOpConversion<RemSIOp, arith::RemSIOp>;
using WasmRemUIOpConversion = BinaryOpConversion<RemUIOp, arith::RemUIOp>;

struct WasmCallOpConversion : OpConversionPattern<FuncCallOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(FuncCallOp funcCallOp, FuncCallOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<func::CallOp>(
        funcCallOp, funcCallOp.getCallee(), funcCallOp.getResults().getTypes(),
        funcCallOp.getOperands());
    return success();
  }
};

struct WasmConstOpConversion : OpConversionPattern<ConstOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ConstOp constOp, ConstOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<arith::ConstantOp>(
        constOp, constOp.getValue());
    return success();
  }
};

struct WasmFuncImportOpConversion : OpConversionPattern<FuncImportOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(FuncImportOp funcImportOp, FuncImportOp::Adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto nFunc = rewriter.replaceOpWithNewOp<func::FuncOp>(
        funcImportOp, funcImportOp.getSymName(),
        funcImportOp.getType());
    nFunc.setVisibility(SymbolTable::Visibility::Private);
    return success();
  }
};

struct WasmFuncOpConversion : OpConversionPattern<FuncOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(FuncOp funcOp, FuncOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto newFunc = rewriter.create<func::FuncOp>(
        funcOp->getLoc(), funcOp.getSymName(), funcOp.getFunctionType());
    rewriter.cloneRegionBefore(funcOp.getBody(), newFunc.getBody(),
                               newFunc.getBody().end());
    rewriter.replaceOp(funcOp, newFunc);
    return success();
  }
};

struct WasmGlobalImportOpConverter : OpConversionPattern<GlobalImportOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(GlobalImportOp gIOp, GlobalImportOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto memrefGOp = rewriter.replaceOpWithNewOp<memref::GlobalOp>(
        gIOp, gIOp.getSymNameAttr(), gIOp.getSymVisibilityAttr(),
        TypeAttr::get(MemRefType::get({1}, gIOp.getType())), Attribute{},
        /*constant*/ UnitAttr{},
        /*alignment*/ IntegerAttr{});
    memrefGOp.setConstant(!gIOp.getIsMutable());
    return success();
  }
};

template<typename CRTP, typename OriginOpType>
struct GlobalOpConverter : OpConversionPattern<GlobalOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(GlobalOp globalOp, GlobalOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ReturnOp rop;
    globalOp->walk([&rop](ReturnOp op) { rop = op; });

    if (rop->getNumOperands() != 1)
      return rewriter.notifyMatchFailure(
          globalOp, "GlobalOp initializer should return one value exactly");

    auto initializerOp = dyn_cast<OriginOpType>(rop->getOperand(0).getDefiningOp());

    if (!initializerOp)
      return rewriter.notifyMatchFailure(
          globalOp, "Invalid initializer op type for this pattern");

    return static_cast<CRTP const *>(this)->handleInitializer(globalOp, rewriter,
                                                       initializerOp);
  }
};

struct WasmGlobalWithConstInitConversion
    : GlobalOpConverter<WasmGlobalWithConstInitConversion, ConstOp> {
  using GlobalOpConverter::GlobalOpConverter;
  LogicalResult handleInitializer(GlobalOp globalOp,
                                  ConversionPatternRewriter &rewriter,
                                  ConstOp constInit) const {
    auto initializer =
        DenseElementsAttr::get(RankedTensorType::get({1}, globalOp.getType()),
                               ArrayRef<Attribute>{constInit.getValueAttr()});
    auto globalReplacement = rewriter.replaceOpWithNewOp<memref::GlobalOp>(
        globalOp, globalOp.getSymNameAttr(), globalOp.getSymVisibilityAttr(),
        TypeAttr::get(MemRefType::get({1}, globalOp.getType())), initializer,
        /*constant*/ UnitAttr{},
        /*alignment*/ IntegerAttr{});
    globalReplacement.setConstant(!globalOp.getIsMutable());
    return success();
  }
};

struct WasmGlobalWithGetGlobalInitConversion
    : GlobalOpConverter<WasmGlobalWithGetGlobalInitConversion, GlobalGetOp> {
  using GlobalOpConverter::GlobalOpConverter;
  LogicalResult handleInitializer(GlobalOp globalOp,
                                  ConversionPatternRewriter &rewriter,
                                  GlobalGetOp constInit) const {
    auto globalReplacement = rewriter.replaceOpWithNewOp<memref::GlobalOp>(
        globalOp, globalOp.getSymNameAttr(), globalOp.getSymVisibilityAttr(),
        TypeAttr::get(MemRefType::get({1}, globalOp.getType())),
        rewriter.getUnitAttr(),
        /*constant*/ UnitAttr{},
        /*alignment*/ IntegerAttr{});
    globalReplacement.setConstant(!globalOp.getIsMutable());
    auto loc = globalOp.getLoc();
    auto initializerName = (globalOp.getSymName() + "::initializer").str();
    auto globalInitializer = rewriter.create<func::FuncOp>(
        loc, initializerName, FunctionType::get(getContext(), {}, {}));
    globalInitializer->setAttr(rewriter.getStringAttr("initializer"),
                               rewriter.getUnitAttr());
    auto *initializerBody = globalInitializer.addEntryBlock();
    auto sip = rewriter.saveInsertionPoint();
    rewriter.setInsertionPointToStart(initializerBody);
    auto srcGlobalPtr = rewriter.create<memref::GetGlobalOp>(
        loc, MemRefType::get({1}, constInit.getType()), constInit.getGlobal());
    auto destGlobalPtr = rewriter.create<memref::GetGlobalOp>(
        loc, globalReplacement.getType(),
        globalReplacement.getSymName());
    auto idx = rewriter.create<arith::ConstantIndexOp>(loc, 0).getResult();
    auto loadSrc =
        rewriter.create<memref::LoadOp>(loc, srcGlobalPtr, ValueRange{idx});
    rewriter.create<memref::StoreOp>(
        loc, loadSrc.getResult(), destGlobalPtr.getResult(), ValueRange{idx});
    rewriter.create<func::ReturnOp>(loc);
    rewriter.restoreInsertionPoint(sip);
    return success();
  }
};

struct WasmMemoryOpConversion : OpConversionPattern<MemOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MemOp memOp, MemOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto loc = memOp.getLoc();
    auto bufferType = MemRefType::get({ShapedType::kDynamic}, rewriter.getI8Type());
    auto bufferPtrType = MemRefType::get({1}, bufferType);
    auto memPtr = rewriter.replaceOpWithNewOp<memref::GlobalOp>(
        memOp, memOp.getSymNameAttr(), memOp.getSymVisibilityAttr(),
        TypeAttr::get(bufferPtrType), /*initialValue*/ rewriter.getUnitAttr(),
        /*constant*/ UnitAttr{}, /*alignment*/ IntegerAttr{});
    auto initializerName = (memPtr.getSymName() + "::initializer").str();
    auto memInitializer = rewriter.create<func::FuncOp>(
        loc, initializerName, FunctionType::get(getContext(), {}, {}));
    memInitializer->setAttr(rewriter.getStringAttr("initializer"),
                            rewriter.getUnitAttr());
    auto *initializerBody = memInitializer.addEntryBlock();
    auto sip = rewriter.saveInsertionPoint();
    rewriter.setInsertionPointToStart(initializerBody);
    auto memRefPtr = rewriter.create<memref::GetGlobalOp>(
        loc, MemRefType::get({1}, bufferType), memPtr.getSymName());
    auto alloc = rewriter.create<memref::AllocOp>(
        loc,
        MemRefType::get({memOp.getLimits().getMin()}, rewriter.getI8Type()));
    auto castOp = rewriter.create<memref::CastOp>(loc, bufferType, alloc.getResult());
    auto idx = rewriter.create<arith::ConstantIndexOp>(loc, 0);
    rewriter.create<memref::StoreOp>(loc, castOp.getResult(),
                                     memRefPtr.getResult(), ValueRange{idx.getResult()});
    rewriter.create<func::ReturnOp>(loc);
    rewriter.restoreInsertionPoint(sip);
    rewriter.create<func::CallOp>(loc, memInitializer);
    return success();
  }
};

struct WasmReturnOpConversion : OpConversionPattern<ReturnOp> {
  using OpConversionPattern::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ReturnOp returnOp, ReturnOp::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<func::ReturnOp>(returnOp, adaptor.getOperands());
    return success();
  }
};

struct ConvertWasmToStandardPass
    : public impl::ConvertWasmToStandardBase<ConvertWasmToStandardPass> {
  void runOnOperation() override {
    ConversionTarget target{getContext()};
    target.addIllegalDialect<WasmDialect>();
    target.addLegalDialect<arith::ArithDialect, BuiltinDialect,
                           func::FuncDialect, memref::MemRefDialect>();
    RewritePatternSet patterns(&getContext());
    TypeConverter tc{};
    tc.addConversion([](Type type) -> std::optional<Type> { return type; });

    populateWasmToStandardConversionPatterns(tc, patterns);

    llvm::DenseMap<StringAttr, StringAttr> idxSymToImportSym{};
    auto *topOp = getOperation();
    topOp->walk([&idxSymToImportSym, this](WasmImportOpInterface importOp) {
      auto const qualifiedImportName = importOp.getQualifiedImportName();
      auto qualNameAttr = StringAttr::get(&getContext(), qualifiedImportName);
      idxSymToImportSym.insert(
          std::make_pair(importOp.getSymbolName(), qualNameAttr));
    });

    if (failed(applyFullConversion(topOp, target, std::move(patterns))))
      return signalPassFailure();

    auto symTable = SymbolTable{topOp};
    for (auto &[oldName, newName] : idxSymToImportSym) {
      if (failed(symTable.rename(oldName, newName)))
        return signalPassFailure();
    }
  }
};
} // namespace

void mlir::populateWasmToStandardConversionPatterns(
    TypeConverter &tc, RewritePatternSet &patternSet) {
  auto *ctx = patternSet.getContext();
  patternSet
      .add<WasmAddOpConversion, WasmCallOpConversion, WasmConstOpConversion,
           WasmDivFPOpConversion, WasmDivSIOpConversion, WasmDivUIOpConversion,
           WasmFuncImportOpConversion, WasmFuncOpConversion,
           WasmGlobalImportOpConverter, WasmGlobalWithConstInitConversion,
           WasmGlobalWithGetGlobalInitConversion, WasmMemoryOpConversion,
           WasmReturnOpConversion, WasmRemSIOpConversion,
           WasmRemUIOpConversion>(tc, ctx);
}
