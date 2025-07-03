# -*- Python -*-

import os

import lit.formats
import lit.util

from lit.llvm import llvm_config

# Configuration file for the 'lit' test runner.

# name: The name of this test suite.
config.name = "Wasabi"

use_lit_shell = True
lit_shell_env = os.environ.get("LIT_USE_INTERNAL_SHELL")
if lit_shell_env:
    use_lit_shell = lit.util.pythonize_bool(lit_shell_env)

config.test_format = lit.formats.ShTest(execute_external=not use_lit_shell)

# suffixes: A list of file extensions to treat as test files.
config.suffixes = [
    ".mlir",
    ".ll"
]

config.excludes = [
    "inputs",
    "CMakeLists.txt",
    "lit.cfg.py",
    "lit.site.cfg.py.in",
]

# test_source_root: The root path where tests are located.
config.test_source_root = os.path.dirname(__file__)

# test_exec_root: The root path where tests should be run.
config.test_exec_root = os.path.join(config.wasabi_obj_root, "test")

config.substitutions.append(("%PATH%", config.environment["PATH"]))
config.substitutions.append(("%shlibext", config.llvm_shlib_ext))
config.substitutions.append(("%llvm_src_root", config.llvm_src_root))
config.substitutions.append(("%host_cxx", config.host_cxx.strip()))
config.substitutions.append(("%host_cc", config.host_cc.strip()))


llvm_config.with_system_environment(["HOME", "INCLUDE", "LIB", "TMP", "TEMP"])

llvm_config.use_default_substitutions()

# Tweak the PATH to include the tools dir.
llvm_config.with_environment("PATH", config.wasabi_bin_dir, append_path=True)
llvm_config.with_environment("PATH", config.llvm_tools_dir, append_path=True)

tool_dirs = [config.wasabi_bin_dir, config.llvm_tools_dir]
tools = [
    "wasabi",
]

python_executable = config.python_executable

# FileCheck -enable-var-scope is enabled by default in MLIR test
# This option avoids to accidentally reuse variable across -LABEL match,
# it can be explicitly opted-in by prefixing the variable name with $
config.environment["FILECHECK_OPTS"] = "-enable-var-scope --allow-unused-prefixes=false"
