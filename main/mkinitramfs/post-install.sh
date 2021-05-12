#!/bin/sh

for h in base modules udev automod; do
	install -m755 /usr/share/mkinitramfs/hooks/$h.hook /etc/mkinitramfs.d/$h.hook
done
