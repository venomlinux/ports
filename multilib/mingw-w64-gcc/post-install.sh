#!/bin/sh

# These libraries need to be run ranlib for fine building of wine
LIBS="libgcc.a libgcc_eh.a"
GWGCC=$(scratch info mingw-w64-gcc | awk '/Installed/{print $2}')

for i in $LIBS; do 

	cd /usr/lib/gcc/i686-w64-mingw32/${GWGCC%-*}/ && i686-w64-mingw32-ranlib $i
done
