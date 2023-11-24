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

case ${0##*/} in
	*-runit.sh) INIT=runit;;
	*) INIT=sysv;;
esac

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"
ROOTFS="$PWD/rootfs"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

MUST_PKG="wpa_supplicant os-prober grub"                         # must have pkg in the iso
XORG_PKG="xorg xorg-video-drivers xf86-input-libinput"           # xorg stuff in the iso
MAIN_PKG="sudo alsa-utils gparted dosfstools mtools gvfs networkmanager ntfs-3g neofetch xdg-user-dirs polkit-gnome ffmpeg geany firefox slim slim-themes fzy"
OPENBOX_PKG="openbox lxappearance lxappearance-obconf obconf obmenu-generator gmrun pcmanfm leafpad feh tint2 consolekit2 irssi mc htop"
THEME_PKG="arcbox papirus-icon-theme-dark papirus-icon-theme-light osx-arc-theme ttf-liberation picom dunst neofetch dfc"
# theme: arc-gtk-theme xfce4-whiskermenu-plugin pop-icon-theme

RELEASE=$(cat $PORTSDIR/current-release)
outputiso="$PORTSDIR/venomlinux-$INIT-$(uname -m)-$(date +%Y%m%d).iso"
pkgs="$(echo $MUST_PKG $XORG_PKG $MAIN_PKG $OPENBOX_PKG $THEME_PKG | tr ' ' ',')"

as_root $SCRIPTDIR/build.sh \
	-zap || exit 1

#echo 'rust rust-bin' | as_root tee -a $ROOTFS/etc/scratchpkg.alias

if [ "$INIT" = runit ]; then
	echo 'rc runit-rc' | as_root tee -a $ROOTFS/etc/scratchpkg.alias
	as_root $ROOTFS/usr/bin/xchroot $ROOTFS scratch remove -y sysvinit rc
	pkgs="$pkgs,runit-rc"
fi

as_root $SCRIPTDIR/build.sh \
	-rebase \
	-iso \
	-outputiso="$outputiso" \
	-pkg="$pkgs" || exit 1

exit 0
