#!/bin/sh
if [ -f /lib/modules/KERNELVERSION ]; then
	kernver=$(cat /lib/modules/KERNELVERSION)
	depmod -a $kernver
fi
 
