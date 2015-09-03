cmake_minimum_required(VERSION 2.8)
project(svc13 LANGUAGES CXX)

find_package(LLVM)

# Define add_llvm_* macro's.
include(AddLLVM)

llvm_replace_compiler_option(CMAKE_CXX_FLAGS "-frtti" "-fno-rtti")

set(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
set(INSTALL_INC_DIR include CACHE PATH "Installation directory for headers")
set(INSTALL_DATA_DIR share/${PROJECT_NAME} CACHE PATH "Installation directory for data files")

add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})
link_directories(${LLVM_LIBRARY_DIRS})

find_path(LLVM_SRC_PATH include/llvm/Module.h)
find_path(LLVM_BUILD_PATH include/llvm/Intrinsics.gen)

if (LLVM_SRC_PATH)
  include_directories(${LLVM_SRC_PATH}/include)
endif(LLVM_SRC_PATH)
if (LLVM_BUILD_PATH)
  include_directories(${LLVM_BUILD_PATH}/include)
  link_directories(${LLVM_BUILD_PATH}/lib)
endif(LLVM_BUILD_PATH)

add_subdirectory(src)
add_subdirectory(lib)
add_subdirectory(include)
add_subdirectory(scripts)

add_custom_target(
	svcversion sh svc_version.sh
)

install(FILES SVC_SCRIPTS_VERSION
	DESTINATION ${CMAKE_INSTALL_PREFIX}/
	OPTIONAL)
