#!/bin/sh

usage() {
	echo "Usage: $0 <flavor>"
	echo
	echo "Flavors:"
	echo "  base, xorg, lxde, xfce4, mate and lxqt"
	echo
	exit 1
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

MUST_PKG="wpa_supplicant os-prober grub"                         # must have pkg in the iso
XORG_PKG="xorg xorg-video-drivers xf86-input-libinput"           # xorg stuff in the iso
MAIN_PKG="pm-utils sudo scrot hexchat audacious audacious-plugins smplayer alsa-utils
	pulseaudio jack simplescreenrecorder ntp gparted dosfstools mtools cantarell-fonts
	liberation-fonts git libmtp gvfs networkmanager ntfs-3g neofetch xdg-user-dirs
	network-manager-applet blueman firefox"
	
mode="-iso"

case $1 in
	rootfs) mode="-rootfs";;
	  base) opt="-pkg=$(echo $MUST_PKG | tr ' ' ',')";;
	  xorg) opt="-pkg=$(echo $MUST_PKG $XORG_PKG | tr ' ' ',')";;
	  lxde) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG lxde lxdm | tr ' ' ',')";;
	  mate) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG mate mate-extra lxdm | tr ' ' ',')";;
	 xfce4) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG xfce4 lxdm | tr ' ' ',')";;
	  lxqt) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG openbox lxqt oxygen-icons5 lxdm | tr ' ' ',')";;
	   all) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG lxde mate mate-extra xfce4 openbox lxqt oxygen-icons5 lxdm | tr ' ' ',')";;
	     *) usage;;
esac

outputiso="$PORTSDIR/venom-$1-$(date +"%Y%m%d").iso"

rm -f $outputiso

sudo ./build.sh \
	-zap \
	-outputiso="$outputiso" \
	$opt $mode

exit 0
