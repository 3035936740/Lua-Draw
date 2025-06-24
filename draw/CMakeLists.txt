# CMakeList.txt: 顶层 CMake 项目文件，在此处执行全局配置
# 并包含子项目。
#
cmake_minimum_required (VERSION 3.22)

project ("lua-draw")

# 将指定目录文件所有复制到二进制文件目录
file(GLOB allCopyFiles  "${CMAKE_CURRENT_SOURCE_DIR}/resource/*")
file(COPY ${allCopyFiles} DESTINATION ${PROJECT_ROOT_NODE}/bin)


set(CMAKE_C_COMPILER "/usr/local/bin/gcc")
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CATKIN_TOPLEVEL TRUE)
# set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_STANDARD 20)
set(LOCAL_LIB_DIR "/usr/local/lib")
# 开启C++20 export/module
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmodules-ts")

# 内存泄露检测
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmodules-ts -fsanitize=address -fno-omit-frame-pointer")
# 内存检测
#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")

# 输出项目信息
message(STATUS ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR})

# 三方库开始
# 头文件
# python三方库相关
set(Python_INCLUDE_DIRS ${Python_DIR}/include)  
set(Python_LIB_DIRS ${Python_DIR}/lib)  

set(VCPKG_LIB ${VCPKG_ROOT}/installed/x64-linux/lib)
set(VCPKG_INCLUDE ${VCPKG_ROOT}/installed/x64-linux/include)
set(LOCAL_INCLUDE /usr/local/include)
set(GLOBAL_INCLUDE /usr/include)
set(SELF_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty)

set(ASPOSE_WORDS_DIR "/usr/local/Aspose.Words.Cpp")
set(ASPOSE_WORDS_CPP "${ASPOSE_WORDS_DIR}/Aspose.Words.Cpp")
set(ASPOSE_WORDS_CODE_PORTING_CPP "${ASPOSE_WORDS_DIR}/CodePorting.Translator.Cs2Cpp.Framework")
set(ASPOSE_WORDS_SHAPING_CPP "${ASPOSE_WORDS_DIR}/Aspose.Words.Shaping.HarfBuzz.Cpp")

include_directories(VCPKG_INCLUDE)
include_directories(LOCAL_INCLUDE)
include_directories(GLOBAL_INCLUDE)

# OpenSSL
include_directories(${OPENSSL_INCLUDE_DIR})

# SQLite Modern C++
set(SQLITE_MODERN_INCLUDE_PATH ${VCPKG_ROOT}/packages/sqlite-modern-cpp_x64-linux)
include_directories(${SQLITE_MODERN_INCLUDE_PATH}/include)

find_package(OpenCV REQUIRED)
find_package(cryptopp CONFIG REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(yaml-cpp REQUIRED)
find_package(spdlog REQUIRED)
find_package(unofficial-sqlite3 CONFIG REQUIRED)
find_package(fmt REQUIRED)
find_package(PythonInterp REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Crow REQUIRED)
find_package(PkgConfig REQUIRED)
# lua库
find_package(Lua REQUIRED)
include_directories(${LUA_INCLUDE_DIR})

# opencv库
include_directories(${OpenCV_INCLUDE_DIRS})

# cairo库
# pkg_check_modules(CAIRO cairo)
# message("found cario: " ${CAIRO_FOUND})
# if (${CAIRO_FOUND})
#     add_definitions(-DMZ_HAVE_CAIRO)
# endif ()
# include_directories(${CAIRO_INCLUDE_DIRS})

#pkg_check_modules(Pistache REQUIRED IMPORTED_TARGET libpistache)
#find_package(unofficial-restbed CONFIG REQUIRED)
add_definitions(-DCROW_ENABLE_SSL)
set(CROW_ENABLE_SSL ON)

find_path(SQLITE_MODERN_CPP_INCLUDE_DIRS "sqlite_modern_cpp.h")
# find_package(libgo CONFIG REQUIRED)

# POCO引入
find_package(Poco REQUIRED COMPONENTS Foundation Net NetSSL JWT JSON Util)

#set(POCO_INSTALL_DIR /usr/lib/x86_64-linux-gnu/cmake/Poco)

#set(Poco_FIND_COMPONENTS Foundation XML Net Util)
#include(${POCO_INSTALL_DIR}/PocoConfig.cmake)

set(GENERATOR_COROUTINE_PATH     ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/generator_coroutine)
set(SNOWFLAKE_CXX_PATH     ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/snowflake-cpp)
include_directories(${GENERATOR_COROUTINE_PATH}/include)
include_directories(${SNOWFLAKE_CXX_PATH}/include)

# bcrypt
set(BCRYPT_PATH     ${SELF_INCLUDE}/Bcrypt-cpp-master)
include_directories(${BCRYPT_PATH}/include)
# 导入a
link_directories(${BCRYPT_PATH}/lib)
link_directories(${VCPKG_LIB})

# imageMagick
find_package(ImageMagick COMPONENTS Magick++)
include_directories(${ImageMagick_INCLUDE_DIRS})

add_definitions(-DMAGICKCORE_QUANTUM_DEPTH=8)
# 设置MagickCore库的HDRI_ENABLE为configure时的默认值
add_definitions(-DMAGICKCORE_HDRI_ENABLE=0)

# aspose.words.cpp
include_directories(
	${ASPOSE_WORDS_CPP}/include
	${ASPOSE_WORDS_CODE_PORTING_CPP}/include
	${ASPOSE_WORDS_CPP}/include
)

link_directories(
	${LOCAL_LIB_DIR}
	${ASPOSE_WORDS_CPP}/lib
	${ASPOSE_WORDS_CODE_PORTING_CPP}/lib
	${ASPOSE_WORDS_SHAPING_CPP}/lib
)

# Local lib
link_directories(${LOCAL_LIB_DIR})
# 三方库结束

# 指定最终的可执行文件的位置
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_ROOT_NODE}/bin)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
# 将源代码添加到此项目的可执行文件。
file(GLOB_RECURSE SRC_LIST 
    "${CMAKE_CURRENT_SOURCE_DIR}/src/**.cpp"
)
add_executable (${PROJECT_NAME} ${SRC_LIST})

#add_subdirectory(openssl)  
#Poco::Net Poco::JSON Poco::Util
#target_include_directories(${PROJECT_NAME} private ${QRENCODE_INCLUDE_DIR})

# 动态库链接
# target_include_directories(${PROJECT_NAME})

target_link_libraries(${PROJECT_NAME} PUBLIC ${OPENSSL_LIBRARIES} ${SQLITE_MODERN_CPP_INCLUDE_DIRS} ${LUA_LIBRARIES} ${OpenCV_LIBS}
${Poco_LIBRARIES} ${ImageMagick_LIBRARIES} nlohmann_json::nlohmann_json fmt::fmt sqlite3 unofficial::sqlite3::sqlite3 
yaml-cpp 
libcodeporting.translator.cs2cpp.framework_x86_64_libstdcpp_libc2.23.so
libAspose.Words.Shaping.HarfBuzz.Cpp.so 
libAspose.Words.Cpp.so
Crow::Crow spdlog::spdlog cryptopp::cryptopp libbcrypt.a)

message(G:${CMAKE_C_COMPILER_VERSION},GXX:${CMAKE_CXX_COMPILER_VERSION},CXX STANDARD:${CMAKE_CXX_STANDARD})
message(final)