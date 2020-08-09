#!/bin/sh

usage() {
	echo "Usage: $0 <flavor>"
	echo
	echo "Flavors:"
	echo "  base, xorg, lxde, xfce4, mate and lxqt"
	echo
	exit 1
}
	
buildiso() {
	outputiso="$PORTSDIR/venom-$1-$(date +"%Y%m%d").iso"

	case $1 in
		  base) opt="-pkg=$(echo $MUST_PKG | tr ' ' ',')";;
		  xorg) opt="-pkg=$(echo $MUST_PKG $XORG_PKG | tr ' ' ',')";;
		  lxde) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG lxde lxdm | tr ' ' ',')";;
		  mate) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG mate mate-extra lxdm | tr ' ' ',')";;
		 xfce4) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG xfce4 lxdm | tr ' ' ',')";;
		  lxqt) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG openbox lxqt oxygen-icons5 lxdm | tr ' ' ',')";;
		   all) opt="-pkg=$(echo $MUST_PKG $XORG_PKG $MAIN_PKG lxde mate mate-extra xfce4 openbox lxqt oxygen-icons5 lxdm | tr ' ' ',')";;
			 *) usage;;
	esac

	if [ -f $outputiso ]; then
		echo "!> skipping iso: $outputiso"
		return 0
	fi

	sudo $SCRIPTDIR/build.sh \
		-zap \
		-iso \
		-outputiso="$outputiso" \
		$opt || exit 1
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

FLAVOR="base xorg lxde mate xfce4 lxqt"
MUST_PKG="wpa_supplicant os-prober grub"                         # must have pkg in the iso
XORG_PKG="xorg xorg-video-drivers xf86-input-libinput"           # xorg stuff in the iso
MAIN_PKG="pm-utils sudo scrot hexchat audacious audacious-plugins smplayer alsa-utils
	pulseaudio jack simplescreenrecorder ntp gparted dosfstools mtools cantarell-fonts
	liberation-fonts git libmtp gvfs networkmanager ntfs-3g neofetch xdg-user-dirs
	network-manager-applet blueman firefox"

if [ "$1" ]; then
	while [ $1 ]; do
		buildiso $1
		shift
	done
else
	for f in $FLAVOR; do
		buildiso $f
	done
fi

exit 0
