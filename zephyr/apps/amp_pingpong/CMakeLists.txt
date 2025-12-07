cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(amp_pingpong)

target_sources(app PRIVATE src/main.c)

set(AMP_PUBLIC_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/../../../include)
if(NOT EXISTS "${AMP_PUBLIC_INCLUDE_DIR}/amp/shmem_layout.h")
	message(FATAL_ERROR "Missing amp/shmem_layout.h; run from repo root")
endif()

target_include_directories(app PRIVATE ${AMP_PUBLIC_INCLUDE_DIR})
