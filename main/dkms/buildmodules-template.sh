#!/bin/sh
# dkms scripts for @name@

[ -f /lib/modules/KERNELVERSION ] && KVER=$(cat /lib/modules/KERNELVERSION)
[ "$KVER" ] || KVER=$(uname -r)

dkms status -m @name@ | while read -r line; do
	module=$(echo $line | sed 's/,//g' | awk '{print $1}')
	kerver=$(echo $line | sed 's/,//g' | awk '{print $2}')
	echo "dkms: remove @name@ modules for kernel $kerver..."
	dkms remove -m $module -k $kerver >/dev/null 2>&1
done

echo "dkms: building @name@ modules for kernel $KVER..."
dkms add -m @name@ -v @version@ -k $KVER >/dev/null 2>&1
dkms build -m @name@ -v @version@ -k $KVER >/dev/null 2>&1
dkms install -m @name@ -v @version@ -k $KVER >/dev/null 2>&1
