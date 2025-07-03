//===- WasmToIR.cpp - Wasabi pass pipeline -----------------------*- C++
//-*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// This is a tool for translating WASM binaries to LLVM IR.
///
//===----------------------------------------------------------------------===//

#include "mlir/CAPI/Registration.h"
#include "mlir/Conversion/ConvertToLLVM/ToLLVMPass.h"
#include "mlir/Conversion/MemRefToLLVM/MemRefToLLVM.h"
#include "mlir/Conversion/ReconcileUnrealizedCasts/ReconcileUnrealizedCasts.h"
#include "mlir/Conversion/RaiseWasm/RaiseWasmMLIR.h"
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Arith/Transforms/Passes.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/LLVMIR/Transforms/LegalizeForExport.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/MemRef/Transforms/Passes.h"
#include "mlir/Dialect/WebAssemblySSA/IR/WebAssemblySSA.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/InitAllExtensions.h"
#include "mlir/InitAllTranslations.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Support/FileUtilities.h"
#include "mlir/Target/LLVMIR/Export.h"
#include "mlir/Target/Wasm/WasmImporter.h"
#include "mlir/Transforms/Passes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"
#include <memory>
#include <string>

using namespace mlir;

MLIR_DEFINE_CAPI_DIALECT_REGISTRATION(WasmSSA, wasmssa, wasmssa::WasmSSADialect)

static MLIRContext currentCtx;

static llvm::cl::opt<std::string> inputFilename(llvm::cl::Positional,
                                                llvm::cl::Required,
                                                llvm::cl::desc("<input file>"));

static llvm::cl::opt<std::string>
    outputFilename("o", llvm::cl::desc("Specify the output filename"),
                   llvm::cl::value_desc("filename"), llvm::cl::init("wasabi.module.out"));

static llvm::cl::opt<std::string>
    outputType("output-type", llvm::cl::desc("Step at which to stop for debug purpose: wasm-mlir or llvm-mlir"),
               llvm::cl::value_desc("step name"));

static llvm::cl::opt<std::string>
    inputType("input-type",
              llvm::cl::desc("Type of input to load: wasm OR wasm-mlir"),
              llvm::cl::init("wasm"));

static llvm::cl::opt<bool> dumpResult("dump", llvm::cl::desc("Print the resulting module to stdout"), llvm::cl::init(false));

LogicalResult runPipelineToLLVMMLIR(OwningOpRef<ModuleOp> &module) {

  auto pm = mlir::PassManager(&currentCtx);
  pm.addPass(mlir::createRaiseWasmMLIRPass());
  pm.addPass(mlir::memref::createExpandOpsPass());
  pm.addPass(mlir::arith::createArithExpandOpsPass());
  pm.addPass(mlir::createFinalizeMemRefToLLVMConversionPass());
  pm.addPass(mlir::createCanonicalizerPass());
  pm.addPass(mlir::LLVM::createLLVMLegalizeForExportPass());
  pm.addPass(mlir::createConvertToLLVMPass());
  pm.addPass(mlir::createReconcileUnrealizedCastsPass());

  return pm.run(*module);
}

OwningOpRef<ModuleOp> loadInputFileToMLIR() {
  std::string errorMessage;
  std::unique_ptr<llvm::MemoryBuffer> inputBuffer =
      mlir::openInputFile(inputFilename, &errorMessage);
  if (!inputBuffer) {
    llvm::errs() << errorMessage << "\n";
    return nullptr;
  }
  auto sourceMgr = std::make_shared<llvm::SourceMgr>();
  sourceMgr->AddNewSourceBuffer(std::move(inputBuffer), llvm::SMLoc());

  if (inputType == "wasm")
    return wasm::importWebAssemblyToModule(*sourceMgr, &currentCtx);

  if (inputType == "wasm-mlir") {
    mlir::OwningOpRef<mlir::ModuleOp> module(
        mlir::parseSourceFile<mlir::ModuleOp>(sourceMgr, &currentCtx));
    return module;
  }
  llvm::errs() << "Unrecognized input type: " << inputType
               << ". Allowed input types are: wasm; wasm-mlir\n";
  return nullptr;
}

void initContext() {
  DialectRegistry dr;
  dr.insert<affine::AffineDialect, arith::ArithDialect,
            bufferization::BufferizationDialect, BuiltinDialect,
            func::FuncDialect, LLVM::LLVMDialect, memref::MemRefDialect,
            wasmssa::WasmSSADialect>();
  registerAllExtensions(dr);
  currentCtx.appendDialectRegistry(dr);
  mlir::registerBuiltinDialectTranslation(currentCtx);
  mlir::registerLLVMDialectTranslation(currentCtx);
}

template <typename T>
llvm::Expected<int> dumpModuleToOutputFile(const T &module) {
  std::string errorMessage;
  std::unique_ptr<llvm::ToolOutputFile> outputBuffer =
      mlir::openOutputFile(outputFilename, &errorMessage);
  if (!outputBuffer) {
    return llvm::createStringError(errorMessage);
  }

  if (dumpResult)
    llvm::outs() << module;
  outputBuffer->os() << module;
  outputBuffer->keep();
  return 0;
}

int main(int argc, char **argv) {
  llvm::ExitOnError ExitOnErr;
  ExitOnErr.setBanner("wasabi: ");
  llvm::cl::ParseCommandLineOptions(argc, argv);

  initContext();

  auto module = loadInputFileToMLIR();
  if (!module)
    return 1;

  if (outputType == "wasm-mlir")
    return ExitOnErr(dumpModuleToOutputFile<ModuleOp>(*module));

  LogicalResult res = runPipelineToLLVMMLIR(module);
  if (failed(res))
    return 1;

  if (outputType == "llvm-mlir")
    return ExitOnErr(dumpModuleToOutputFile<ModuleOp>(*module));

  llvm::LLVMContext llvmCtx;
  std::unique_ptr<llvm::Module> llvmModule =
      mlir::translateModuleToLLVMIR(*module, llvmCtx, "WasmModule");

  return ExitOnErr(dumpModuleToOutputFile<llvm::Module>(*llvmModule));
}
