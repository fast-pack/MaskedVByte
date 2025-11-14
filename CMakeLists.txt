cmake_minimum_required(VERSION 3.15)

project(MaskedVByte VERSION 0.0.1 LANGUAGES C)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(CheckCCompilerFlag)

option(MASKEDVBYTE_BUILD_EXAMPLES "Build examples" ON)
option(MASKEDVBYTE_BUILD_TESTS "Build tests" ON)

# Library
add_library(maskedvbyte
    src/varintdecode.c
    src/varintencode.c
)
add_library(maskedvbyte::maskedvbyte ALIAS maskedvbyte)

# Public headers
set(MASKEDVBYTE_PUBLIC_HEADERS
    include/varintdecode.h
    include/varintencode.h
)

# Properties
set_target_properties(maskedvbyte PROPERTIES
    OUTPUT_NAME maskedvbyte
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    POSITION_INDEPENDENT_CODE ON
)

target_compile_features(maskedvbyte PUBLIC c_std_99)

target_include_directories(maskedvbyte
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# Enable SSE4.1 on GCC/Clang when available
if (CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang|GNU")
    check_c_compiler_flag("-msse4.1" HAS_SSE41_FLAG)
    if (HAS_SSE41_FLAG)
        target_compile_options(maskedvbyte PRIVATE -msse4.1)
    endif()
endif()

# Examples
if (MASKEDVBYTE_BUILD_EXAMPLES)
    add_executable(example examples/example.c)
    target_link_libraries(example PRIVATE maskedvbyte)
    target_compile_features(example PRIVATE c_std_99)
    target_include_directories(example PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
endif()

# Tests
if (MASKEDVBYTE_BUILD_TESTS)
    include(CTest)
    add_executable(unit tests/unit.c)
    target_link_libraries(unit PRIVATE maskedvbyte)
    target_compile_features(unit PRIVATE c_std_99)
    target_include_directories(unit PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    add_test(NAME maskedvbyte_unit COMMAND unit)
endif()

# Install rules
install(TARGETS maskedvbyte
    EXPORT maskedvbyteTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES ${MASKEDVBYTE_PUBLIC_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Package config and export
install(EXPORT maskedvbyteTargets
    NAMESPACE maskedvbyte::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/maskedvbyte
)

configure_package_config_file(
    cmake/maskedvbyteConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/maskedvbyteConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/maskedvbyte
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/maskedvbyteConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/maskedvbyteConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/maskedvbyteConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/maskedvbyte
)

# Export from build tree for convenience
export(EXPORT maskedvbyteTargets
    NAMESPACE maskedvbyte::
    FILE ${CMAKE_CURRENT_BINARY_DIR}/maskedvbyteTargets.cmake
)
