#!/bin/sh

# The port 'mingw-w64-gcc-base' conflicts with 'mingw-w64-gcc', remove 'mingw-w64-gcc-base' before installing 'mingw-w64-gcc'
scratch isinstalled mingw-w64-gcc-base && scratch remove -y mingw-w64-gcc-base
