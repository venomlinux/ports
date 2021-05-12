#!/bin/sh

if [ -f /lib/modules/KERNELVERSION ]; then
	kernver=$(cat /lib/modules/KERNELVERSION)
else
	kernver=$(uname -r)
fi
if [ $(type -p mkinitramfs) ]; then
	mkinitramfs -q -k $kernver -o /boot/initrd-venom.img
fi
depmod $kernver
