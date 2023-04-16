#!/bin/sh
#
# this script will be execute by venom-installer after system unsquashed
#
 
# copy over all customs configs and customization except some unnecessary files
for i in $(find $VIROOTFS -type f | sed "s,$VIROOTFS,,"); do
    case $i in
        *venom-installer*|*custom_script.sh|*fstab|*issue|*venominstaller.desktop|*post-install.sh) continue;;
    esac
    install -D $VIROOTFS/$i $ROOT/$i
done

# remove install venom entry from ob menu
sed '/Install Venom/d' -i $ROOT/etc/skel/.config/obmenu-generator/schema.pl

# remove welcome message entry from autostart
sed '/xterm/d' -i $ROOT/etc/skel/.config/openbox/autostart

# change slim theme
if [ -d $ROOT/usr/share/slim/themes/greeny_dark ] && [ -f $ROOT/etc/slim.conf ]; then
	sed "s/current_theme.*/current_theme greeny_dark/" -i $ROOT/etc/slim.conf
fi

exit 0
