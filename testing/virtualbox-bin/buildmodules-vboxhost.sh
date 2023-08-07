#!/bin/sh

if [ -d /lib/modules/$(uname -r) ]; then
	echo "dkms: building @name@ modules..."
	rm -fr /var/lib/dkms/@name@
	dkms add -m @name@ -v @version@ >/dev/null 2>&1
	dkms build -m @name@ -v @version@ >/dev/null 2>&1
	dkms install -m @name@ -v @version@ >/dev/null 2>&1
fi
