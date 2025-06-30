// RUN: mlir-opt %s -verify-diagnostics

module {
  wasmssa.import_global "glob" from "my_module" as @global_0 mutable nested : i32
  // expected-error@+1 {{Expected a constant initializer for this operator}}
  wasmssa.global @global_1 i32 : {
  // expected-error@+1 {{global.get op is considered constant if it's referring to a import.global symbol marked non-mutable}}
    %0 = wasmssa.global_get @global_0 : i32
    wasmssa.return %0 : i32
  }
}
