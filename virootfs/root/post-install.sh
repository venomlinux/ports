#!/bin/sh
#
# this script will be execute by venom-installer to do some stuffs
# after venom is installed
#
 
VIROOTFS=${VIROOTFS:-/run/initramfs/medium/virootfs/}
VENOMROOTFS=${VENOMROOTFS:-/tmp/venominstall}
 
# copy over all customs configs and customization except some unnecessary files
for i in $(find $VIROOTFS -type f | sed "s,$VIROOTFS,,"); do
    case $i in
        *venom-installer*|*custom_script.sh|*fstab|*issue|*venominstaller.desktop|*post-install.sh) continue;;
    esac
    install -D $VIROOTFS/$i $VENOMROOTFS/$i
done

#xchroot $VENOMROOTFS sh /root/customization.sh
# skels not automatically copied over when user created through chroot
# so use this for now
#for user in $VENOMROOTFS/home/*; do
	#USER=${user##*/}
	#cp -r /etc/skel/.* /etc/skel/* $VENOMROOTFS/home/$USER
	#chown -R $USER:$USER /home/$USER/.* $VENOMROOTFS/home/$USER/*
#done

# remove install venom entry from ob menu
sed '/Install Venom/d' -i $VENOMROOTFS/etc/skel/.config/obmenu-generator/schema.pl

# remove welcome message entry from autostart
sed '/xterm/d' -i $VENOMROOTFS/etc/skel/.config/openbox/autostart

# change slim theme
[ -d /usr/share/slim/themes/greeny_dark ] && {
	sed "s/current_theme.*/current_theme greeny_dark/" -i $VENOMROOTFS/etc/slim.conf
}

exit 0
