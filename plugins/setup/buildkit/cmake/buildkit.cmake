# buildkit.cmake — Build Go core as part of the native Linux/Windows build
#
# Include this from a plugin's CMakeLists.txt and call:
#   apply_buildkit()
#
# This adds a target that runs build_tool before the native target is linked.

# Resolve at include-time so CMAKE_CURRENT_LIST_DIR is this file's directory
get_filename_component(BUILDKIT_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)

function(buildkit_output_root OUT_VAR)
  get_filename_component(_root "${CMAKE_SOURCE_DIR}" DIRECTORY)
  if(DEFINED ENV{BUILDKIT_OUTPUT_DIR} AND NOT "$ENV{BUILDKIT_OUTPUT_DIR}" STREQUAL "")
    get_filename_component(_output_root "$ENV{BUILDKIT_OUTPUT_DIR}" ABSOLUTE BASE_DIR "${_root}")
  else()
    set(_output_root "${_root}/libclash")
  endif()
  set(${OUT_VAR} "${_output_root}" PARENT_SCOPE)
endfunction()

function(apply_buildkit)
  if(WIN32)
    set(_launcher "${BUILDKIT_DIR}/run_build_tool.cmd")
  else()
    set(_launcher "${BUILDKIT_DIR}/run_build_tool.sh")
  endif()

  # Project root is one level up from CMAKE_SOURCE_DIR (the top-level CMakeLists.txt
  # lives in linux/ or windows/, so project root is the parent).
  get_filename_component(PROJECT_ROOT "${CMAKE_SOURCE_DIR}" DIRECTORY)
  buildkit_output_root(_artifact_root)

  # Both Windows artifacts are byproducts of the same toolchain invocation.
  if(WIN32)
    set(_output
      "${_artifact_root}/windows/QuanClashCore.exe"
      "${_artifact_root}/windows/QuanClashHelperService.exe")
    set(_platform_args "windows")
  else()
    set(_output "${_artifact_root}/linux/QuanClashCore")
    set(_platform_args "linux")
  endif()

  set(BUILDKIT_ENV
    "BUILDKIT_CONFIGURATION=$<CONFIG>"
    "PROJECT_DIR=${PROJECT_ROOT}"
  )
  if(DEFINED ENV{BUILDKIT_OUTPUT_DIR} AND NOT "$ENV{BUILDKIT_OUTPUT_DIR}" STREQUAL "")
    list(APPEND BUILDKIT_ENV "BUILDKIT_OUTPUT_DIR=${_artifact_root}")
  endif()

  # Language toolchains cache unchanged sources. An existence-only command can
  # silently package stale core code or reuse the wrong Debug/Release helper.
  add_custom_target(setup_buildkit_build
    BYPRODUCTS ${_output}
    COMMAND ${CMAKE_COMMAND} -E env ${BUILDKIT_ENV}
    "${_launcher}" ${_platform_args}
    WORKING_DIRECTORY "${PROJECT_ROOT}"
    COMMENT "Building Go core via buildkit..."
    VERBATIM
  )

endfunction()
