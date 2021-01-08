#!/bin/sh

as_root()
{
	if [ $(id -u) = 0 ]; then
		$*
	elif [ -x /usr/bin/sudo ]; then
		sudo $*
	else
		su -c \\"$*\\"
	fi
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

MUST_PKG="wpa_supplicant os-prober grub"                         # must have pkg in the iso
XORG_PKG="xorg xorg-video-drivers xf86-input-libinput"           # xorg stuff in the iso
MAIN_PKG="pm-utils sudo scrot hexchat audacious audacious-plugins smplayer alsa-utils
	pulseaudio jack simplescreenrecorder ntp gparted dosfstools mtools cantarell-fonts
	liberation-fonts git libmtp gvfs networkmanager ntfs-3g neofetch xdg-user-dirs
	network-manager-applet blueman firefox thunderbird xfce4 lxdm"
# theme: arc-gtk-theme xfce4-whiskermenu-plugin pop-icon-theme

outputiso="$PORTSDIR/venomlinux-$(date +"%Y%m%d").iso"
pkgs="$(echo $MUST_PKG $XORG_PKG $MAIN_PKG | tr ' ' ',')"

as_root $SCRIPTDIR/build.sh \
	-zap \
	-iso \
	-outputiso="$outputiso" \
	-pkg="$pkgs" || exit 1

exit 0
