#!/bin/sh

for h in base modules udev automod; do
	if [ -f /etc/mkinitramfs.d/$h.hook ]; then
		install -m755 /usr/share/mkinitramfs/hooks/$h.hook /etc/mkinitramfs.d/$h.hook.spkgnew
	else
		install -m755 /usr/share/mkinitramfs/hooks/$h.hook /etc/mkinitramfs.d/$h.hook
	fi
done
