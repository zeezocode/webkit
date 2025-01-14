if (CMAKE_VERSION VERSION_LESS 3.14)
    message(FATAL_ERROR "CMake 3.14 or greater is required to compile WebKitFTW")
endif ()

if (MSVC_VERSION VERSION_LESS 1920)
    message(FATAL_ERROR "Visual Studio 2019 is required to compile WebKitFTW")
endif ()

if (${WTF_CPU_X86})
    message(FATAL_ERROR "WebKitFTW does not support 32-bit builds")
endif ()

set(PORT FTW)

# Compilation options
include(OptionsMSVC)

add_definitions(-DWTF_PLATFORM_FTW=1)
# Prevent min() and max() macros from being exposed
add_definitions(-DNOMINMAX)
# Use unicode
add_definitions(-DUNICODE -D_UNICODE)
# If <winsock2.h> is not included before <windows.h> redefinition errors occur
# unless _WINSOCKAPI_ is defined before <windows.h> is included
add_definitions(-D_WINSOCKAPI_=)

# Setup library paths
if (NOT WEBKIT_LIBRARIES_DIR)
    if (DEFINED ENV{WEBKIT_LIBRARIES})
        file(TO_CMAKE_PATH "$ENV{WEBKIT_LIBRARIES}" WEBKIT_LIBRARIES_DIR)
    else ()
        file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}/WebKitLibraries/win" WEBKIT_LIBRARIES_DIR)
    endif ()
endif ()

set(CMAKE_PREFIX_PATH ${WEBKIT_LIBRARIES_DIR})

set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB32_PATHS OFF)
set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib64)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib64)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin64)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

WEBKIT_OPTION_BEGIN()

# Enabled features

# Experimental features
WEBKIT_OPTION_DEFAULT_PORT_VALUE(ENABLE_REMOTE_INSPECTOR PRIVATE ${ENABLE_EXPERIMENTAL_FEATURES})
WEBKIT_OPTION_DEFAULT_PORT_VALUE(ENABLE_RESOURCE_USAGE PRIVATE ${ENABLE_EXPERIMENTAL_FEATURES})

# Features to investigate
#
# Features that are temporarily turned off because an implementation is not
# present at this time
WEBKIT_OPTION_DEFAULT_PORT_VALUE(ENABLE_FTL_JIT PRIVATE OFF)

# No support planned

# FIXME: Port bmalloc to Windows. https://bugs.webkit.org/show_bug.cgi?id=143310
WEBKIT_OPTION_DEFAULT_PORT_VALUE(USE_SYSTEM_MALLOC PRIVATE ON)

WEBKIT_OPTION_END()

find_package(ICU REQUIRED COMPONENTS data i18n uc)

SET_AND_EXPOSE_TO_BUILD(USE_EXPORT_MACROS ON)
SET_AND_EXPOSE_TO_BUILD(USE_INSPECTOR_SOCKET_SERVER ${ENABLE_REMOTE_INSPECTOR})

set(WTF_LIBRARY_TYPE SHARED)
set(JavaScriptCore_LIBRARY_TYPE SHARED)

set(ENABLE_API_TESTS OFF)
set(ENABLE_WEBCORE OFF)
set(ENABLE_WEBKIT OFF)
set(ENABLE_WEBKIT_LEGACY OFF)

# Override headers directories
set(WTF_FRAMEWORK_HEADERS_DIR ${CMAKE_BINARY_DIR}/WTF/Headers)
set(JavaScriptCore_FRAMEWORK_HEADERS_DIR ${CMAKE_BINARY_DIR}/JavaScriptCore/Headers)
set(JavaScriptCore_PRIVATE_FRAMEWORK_HEADERS_DIR ${CMAKE_BINARY_DIR}/JavaScriptCore/PrivateHeaders)

# Override derived sources directories
set(WTF_DERIVED_SOURCES_DIR ${CMAKE_BINARY_DIR}/WTF/DerivedSources)
set(JavaScriptCore_DERIVED_SOURCES_DIR ${CMAKE_BINARY_DIR}/JavaScriptCore/DerivedSources)

# Override scripts directories
set(WTF_SCRIPTS_DIR ${CMAKE_BINARY_DIR}/WTF/Scripts)
set(JavaScriptCore_SCRIPTS_DIR ${CMAKE_BINARY_DIR}/JavaScriptCore/Scripts)
