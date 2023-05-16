#!/bin/sh
# These libraries need to be run ranlib for fine building of mingw-w64-gcc
LIBS="libpthread.dll.a"

for i in $LIBS; do 
	cd /usr/i686-w64-mingw32/lib && i686-w64-mingw32-ranlib $i
done
