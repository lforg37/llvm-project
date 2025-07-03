configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
  )

set(WASABI_TEST_DEPENDS
  wasabi)

add_custom_target(wasabi-test-depends DEPENDS ${WASABI_TEST_DEPENDS})
set_target_properties(wasabi-test-depends PROPERTIES FOLDER "wasabi/tests")

add_lit_testsuite(check-wasabi "Running the Wasabi tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${WASABI_TEST_DEPENDS}
  )

add_lit_testsuites(MLIR ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS ${WASABI_TEST_DEPENDS}
)
