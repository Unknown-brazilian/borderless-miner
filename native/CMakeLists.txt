cmake_minimum_required(VERSION 3.10)
project(miner C)

# Gera libminer.so (carregada no Dart via DynamicLibrary.open('libminer.so')).
add_library(miner SHARED miner.c)

# Otimização agressiva; -ftree-vectorize ajuda no NEON em ARM.
target_compile_options(miner PRIVATE -O3 -ffast-math -ftree-vectorize)

# Mantém os símbolos exportados visíveis para o dlopen/FFI.
set_target_properties(miner PROPERTIES C_VISIBILITY_PRESET default)
