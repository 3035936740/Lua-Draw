# CMakeList.txt: 顶层 CMake 项目文件，在此处执行全局配置
# 并包含子项目。
#
cmake_minimum_required (VERSION 3.22)

project ("luadraw")

# 将指定目录文件所有复制到二进制文件目录
file(GLOB allCopyFiles  "${CMAKE_CURRENT_SOURCE_DIR}/resource/*")
file(COPY ${allCopyFiles} DESTINATION ${PROJECT_ROOT_NODE}/bin)

set(CMAKE_C_COMPILER "/usr/local/bin/gcc")
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CATKIN_TOPLEVEL TRUE)
# set(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CXX_STANDARD 20)
set(LOCAL_LIB_DIR "/usr/local/lib")

# 输出项目信息
message(STATUS ${PROJECT_NAME} ${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR})

# 三方库开始
# 头文件
set(VCPKG_LIB ${VCPKG_ROOT}/installed/x64-linux/lib)
set(VCPKG_INCLUDE ${VCPKG_ROOT}/installed/x64-linux/include)
set(LOCAL_INCLUDE /usr/local/include)
set(GLOBAL_INCLUDE /usr/include)
set(SELF_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty)

include_directories(VCPKG_INCLUDE)
include_directories(LOCAL_INCLUDE)
include_directories(GLOBAL_INCLUDE)

find_package(OpenCV REQUIRED)
find_package(Freetype REQUIRED)
find_package(fmt REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(Lua REQUIRED)

# lua库
include_directories(${LUA_INCLUDE_DIR})

# opencv库
include_directories(${OpenCV_INCLUDE_DIRS})

# Freetype引入
include_directories(${FREETYPE_INCLUDE_DIRS})

# Local lib
link_directories(${LOCAL_LIB_DIR})
# 三方库结束

# 指定最终的可执行文件的位置
set(LIBRARY_OUTPUT_PATH ${PROJECT_ROOT_NODE}/bin)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

# 将源代码添加到此项目的可执行文件。
file(GLOB_RECURSE SRC_LIST 
    "${CMAKE_CURRENT_SOURCE_DIR}/src/**.cpp"
)
add_library(${PROJECT_NAME} SHARED ${SRC_LIST})

target_link_libraries(${PROJECT_NAME} PUBLIC ${LUA_LIBRARIES} ${OpenCV_LIBS}
nlohmann_json::nlohmann_json fmt::fmt Freetype::Freetype)

message(G:${CMAKE_C_COMPILER_VERSION},GXX:${CMAKE_CXX_COMPILER_VERSION},CXX STANDARD:${CMAKE_CXX_STANDARD})
message(final)