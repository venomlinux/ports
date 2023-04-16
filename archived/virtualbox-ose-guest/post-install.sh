#!/bin/sh

getent group vboxsf >/dev/null || groupadd -r vboxsf
chgrp vboxsf /media
sh /var/lib/dkms/buildmodules-vboxguest.sh
echo "mkinitramfs: regenerate initramfs to include vbox modules..."
mkinitramfs -q -k $kernver -o /boot/initrd-venom.img -a vboxguest
