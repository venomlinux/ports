#!/bin/sh

# These libraries need to be run ranlib for fine building of winpthreads
LIBS="libmingw32.a libmingwex.a libmoldname.a libmingwthrd.a libmingw32.a libmoldname.a libmingwex.a libmsvcrt.a libkernel32.a libadvapi32.a libshell32.a libuser32.a libuserenv.a libgcc_s.a"

for i in $LIBS; do 
	cd /usr/i686-w64-mingw32/lib && i686-w64-mingw32-ranlib $i
done
