#!/bin/sh
#
# /root/pre-install.sh
# this script is executed by venom-install after system is extracted to disk
#

if [ -f "/run/initramfs/ram/filesystem.sfs" ]; then
	VIROOTFS="/run/initramfs/ram/virootfs/"
else
	VIROOTFS="/run/initramfs/medium/virootfs/"
fi

ROOT=/mnt/install

# copy over all customs configs and customization except some unnecessary files
for i in $(find $VIROOTFS -type f | sed "s,$VIROOTFS,,"); do
    case $i in
        root/*|*venom-installer*|*fstab|*issue|*venominstaller.desktop) continue;;
    esac
    install -D $VIROOTFS/$i $ROOT/$i
done

# remove install venom entry from ob menu
sed '/Install Venom/d' -i $ROOT/etc/skel/.config/obmenu-generator/schema.pl

# remove welcome message entry from autostart
sed '/xterm/d' -i $ROOT/etc/skel/.config/openbox/autostart

# change slim theme
[ -d /usr/share/slim/themes/greeny_dark ] && {
        sed "s/current_theme.*/current_theme greeny_dark/" -i $ROOT/etc/slim.conf
}
