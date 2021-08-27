#!/bin/bash
#
# script to operate Venom Linux through chroot environment
#

interrupted() {
	unmount_any_mounted
	exit 1
}

mount_ccache() {
	mkdir -p $ROOTFS/var/lib/ccache
	mount --bind $CCACHE_DIR $ROOTFS/var/lib/ccache
}

umount_ccache() {
	unmount $ROOTFS/var/lib/ccache
	rm -fr $ROOTFS/var/lib/ccache
}

mount_pseudofs() {
	mount --bind /dev $ROOTFS/dev
	mount -t devpts devpts $ROOTFS/dev/pts -o gid=5,mode=620
	mount -t proc proc $ROOTFS/proc
	mount -t sysfs sysfs $ROOTFS/sys
	mount -t tmpfs tmpfs $ROOTFS/run
}

umount_pseudofs() {
	for d in run sys proc dev/pts dev; do
		unmount $ROOTFS/$d
	done
}

bindmount() {
	mount --bind $1 $2
}

unmount() {
	while true; do
		mountpoint -q $1 || break
		umount $1 2>/dev/null
	done
}

chrootrun() {
	mount_cache_and_portsrepo
	mount_pseudofs
	mount_ccache
	cp -L /etc/resolv.conf $ROOTFS/etc/
	chroot $ROOTFS /usr/bin/env -i PATH=/usr/lib/ccache:$PATH CCACHE_DIR=/var/lib/ccache TERM=$TERM SHELL=/bin/sh LANG=en_US.UTF-8 $@
	retval=$?
	umount_ccache
	umount_pseudofs
	umount_cache_and_portsrepo
	return $retval
}

umount_cache_and_portsrepo() {
	# unmount packages and source cache
	unmount $ROOTFS/var/cache/scratchpkg/packages
	unmount $ROOTFS/var/cache/scratchpkg/sources
	
	# mount ports dir
	umount_repo
}

umount_repo() {
	for repo in $REPO; do
		unmount $ROOTFS/usr/ports/$repo
		rm -rf $ROOTFS/usr/ports/$repo
	done
}

unmount_any_mounted() {
	for m in $(findmnt --list | grep $ROOTFS | awk '{print $1}' | sort | tac); do
		unmount $m
	done
}

mount_cache_and_portsrepo() {
	# umount all mounted first
	unmount_any_mounted

	# mount pkgs and srcs dir
	bindmount $SRCDIR $ROOTFS/var/cache/scratchpkg/sources
	bindmount $PKGDIR $ROOTFS/var/cache/scratchpkg/packages

	# mount ports dir
	mount_repo
}

mount_repo() {
	for repo in $REPO; do
		[ -d "$PORTSDIR/$repo" ] || {
			msgerr "repo not exist: $repo"
		}
		mkdir -p "$ROOTFS/usr/ports/$repo"
		bindmount "$PORTSDIR/$repo" "$ROOTFS/usr/ports/$repo"
	done
}

fetch_rootfs() {
	url="https://github.com/venomlinux/ports/releases/download/v$RELEASE/venomlinux-rootfs-$RELEASE-$ARCH.tar.xz"

	msg "Fetching rootfs tarball: $url"
	wget -c --passive-ftp --no-directories --tries=3 --waitretry=3 --output-document=$TARBALLIMG.part $url
	if [ "$?" = 0 ]; then
		rm -f "$TARBALLIMG"
		mv "$TARBALLIMG".part "$TARBALLIMG"
	else
		die "Error fetching rootfs tarball"
	fi
}

zap_rootfs() {
	unmount_any_mounted
	
	# make sure new extracted rootfs is uptodate and clean from broken pkgs
	SYSUP=1
	REVDEP=1
	
	[ -f "$TARBALLIMG" ] || {
		fetch_rootfs
	}
	msg "Removing existing rootfs: $ROOTFS"
	rm -fr $ROOTFS
	mkdir -p $ROOTFS
	msg "Extracting tarball image: $TARBALLIMG"
	tar -xf $TARBALLIMG -C $ROOTFS || die "Error extracting tarball image"
	tmp_scratchpkgconf
	#echo "$RELEASE" > "$ROOTFS"/etc/venom-release
	unset ZAP
}

compress_rootfs() {
	pushd $ROOTFS >/dev/null
	
	[ -f "$TARBALLIMG" ] && {
		msg "Backup current rootfs..."
		mv "$TARBALLIMG" "$TARBALLIMG".bak
	}
	
	msg "Copying ports and repofile..."
	copy_ports
	main_scratchpkgconf
	
	msg "Compressing rootfs: $ROOTFS ..."
	tar --exclude="var/cache/scratchpkg/packages/*" \
		--exclude="var/cache/scratchpkg/sources/*" \
		--exclude="var/cache/scratchpkg/work/*" \
		--exclude="*.spkgnew" \
		--exclude="tmp/*" \
		--exclude="root/*" \
		-cvJpf "$TARBALLIMG" * | while read -r line; do
			echo -ne " $line\033[0K\r"
		done
		if [ "$?" != 0 ]; then
			msgerr "Failed compressing rootfs..."
			rm -f "$TARBALLIMG"
			[ -f "$TARBALLIMG".bak ] && {
				msg "Restore backup rootfs..."
				mv "$TARBALLIMG".bak "$TARBALLIMG"
			}
		else
			msg "Rootfs compressed: $TARBALLIMG"
			rm -f "$TARBALLIMG".bak
		fi
	popd >/dev/null
}

check_rootfs() {
	[ -d $ROOTFS/dev ] || zap_rootfs
}

tmp_scratchpkgconf() {
	mv "$ROOTFS"/etc/scratchpkg.repo "$ROOTFS"/etc/scratchpkg.repo.spkgnew
	for i in $REPO; do
		echo "/usr/ports/$i" >> "$ROOTFS"/etc/scratchpkg.repo
	done
	cp "$ROOTFS"/etc/scratchpkg.conf "$ROOTFS"/etc/scratchpkg.conf.spkgnew
	sed "s/MAKEFLAGS=.*/MAKEFLAGS=\"-j$JOBS\"/" -i "$ROOTFS"/etc/scratchpkg.conf
}

main_scratchpkgconf() {
	chrootrun scratch install -r -y --no-backup scratchpkg
	#if [ -f $ROOTFS/etc/scratchpkg.repo.spkgnew ]; then
	#	mv $ROOTFS/etc/scratchpkg.repo.spkgnew $ROOTFS/etc/scratchpkg.repo
	#fi
	#if [ -f $ROOTFS/etc/scratchpkg.conf.spkgnew ]; then
	#	mv $ROOTFS/etc/scratchpkg.conf.spkgnew $ROOTFS/etc/scratchpkg.conf
	#fi
}

copy_ports() {
	rm -fr $ROOTFS/usr/ports
	mkdir -p $ROOTFS/usr/ports
	[ -d $PORTSDIR/main ] || {
		msg "main repo not exist"
		return 1
	}
	msg "Copying main repo..."
	cp -Ra $PORTSDIR/main $ROOTFS/usr/ports || exit 1
	rm -f $ROOTFS/usr/ports/main/REPO
	rm -f $ROOTFS/usr/ports/main/.httpup-repgen-ignore
	rm -f $ROOTFS/usr/ports/main/*/update
	chown -R 0:0 $ROOTFS/usr/ports/main
}

make_iso() {
	ISOLINUX_FILES="chain.c32 isolinux.bin ldlinux.c32 libutil.c32 reboot.c32 vesamenu.c32 libcom32.c32 poweroff.c32"
	# prepare isolinux files
	msg "Preparing isolinux..."
	rm -fr "$ISODIR"
	mkdir -p "$ISODIR"/{rootfs,isolinux,efi/boot,boot}
	for file in $ISOLINUX_FILES; do
		cp "$ROOTFS/usr/share/syslinux/$file" "$ISODIR/isolinux" || die "Failed copying isolinux file: $file"
	done
	cp "$FILESDIR/splash.png" "$ISODIR/isolinux"
	cp "$FILESDIR/isolinux.cfg" "$ISODIR/isolinux"
	
	[ -d "$PORTSDIR/virootfs" ] && {
		cp -aR "$PORTSDIR/virootfs" "$ISODIR"
		chown -R 0:0 "$ISODIR/virootfs"
	}
	
	main_scratchpkgconf
	copy_ports
	#chrootrun scratch install -y scratchpkg
	#sed "s/MAKEFLAGS=.*/MAKEFLAGS=\"-j\$(nproc\)\"/" -i "$ROOTFS"/etc/scratchpkg.conf
	
	# make sfs
	msg "Squashing root filesystem: $ISODIR/rootfs/filesystem.sfs ..."
	mksquashfs "$ROOTFS" "$ISODIR/rootfs/filesystem.sfs" \
			-b 1048576 -comp zstd \
			-e "$ROOTFS"/var/cache/scratchpkg/sources/* \
			-e "$ROOTFS"/var/cache/scratchpkg/packages/* \
			-e "$ROOTFS"/var/cache/scratchpkg/work/* \
			-e "$ROOTFS"/root/* \
			-e "$ROOTFS"/tmp/* \
			-e "*.spkgnew" 2>/dev/null || die "Failed create sfs root filesystem"
			
	cp "$ROOTFS/boot/vmlinuz-venom" "$ISODIR/boot/vmlinuz" || die "Failed copying kernel"
	
	sed "s/@ISOLABEL@/$ISOLABEL/g" "$FILESDIR/venomiso.hook" > "$ROOTFS/etc/mkinitramfs.d/venomiso.hook" || die "Failed preparing venomiso.hook"
	kernver=$(file $ROOTFS/boot/vmlinuz-venom | cut -d ' ' -f9)
	chrootrun mkinitramfs -k $kernver -a venomiso || die "Failed create initramfs"
	cp "$ROOTFS/boot/initrd-venom.img" "$ISODIR/boot/initrd" || die "Failed copying initrd"
	
	msg "Setup UEFI mode..."
	mkdir -p "$ISODIR"/boot/grub/{fonts,x86_64-efi}
	if [ -f $ROOTFS/usr/share/grub/unicode.pf2 ];then
		cp "$ROOTFS/usr/share/grub/unicode.pf2" "$ISODIR/boot/grub/fonts"
	fi
	if [ -f "$ISODIR/isolinux/splash.png" ]; then
		cp "$ISODIR/isolinux/splash.png" "$ISODIR/boot/grub/"
	fi
	echo "set prefix=/boot/grub" > "$ISODIR/boot/grub-early.cfg"
	cp -a $ROOTFS/usr/lib/grub/x86_64-efi/*.{mod,lst} "$ISODIR/boot/grub/x86_64-efi" || die "Failed copying efi files"
	cp "$FILESDIR/grub.cfg" "$ISODIR/boot/grub/"

	grub-mkimage -c "$ISODIR/boot/grub-early.cfg" -o "$ISODIR/efi/boot/bootx64.efi" -O x86_64-efi -p "" iso9660 normal search search_fs_file
	modprobe loop
	dd if=/dev/zero of=$ISODIR/boot/efiboot.img count=4096
	mkdosfs -n VENOM-UEFI "$ISODIR/boot/efiboot.img" || die "Failed create mkdosfs image"
	mkdir -p "$ISODIR/boot/efiboot"
	mount -o loop "$ISODIR/boot/efiboot.img" "$ISODIR/boot/efiboot" || die "Failed mount efiboot.img"
	mkdir -p "$ISODIR/boot/efiboot/EFI/boot"
	cp "$ISODIR/efi/boot/bootx64.efi" "$ISODIR/boot/efiboot/EFI/boot"
	unmount "$ISODIR/boot/efiboot"
	rm -fr "$ISODIR/boot/efiboot"

	# save list packages to iso
	for pkg in base linux $(echo $PKG | tr ',' ' '); do
		echo "$pkg" >> "$ISODIR/rootfs/pkglist"
	done

	msg "Making iso: $OUTPUTISO ..."
	rm -f "$OUTPUTISO" "$OUTPUTISO.md5"
	xorriso -as mkisofs \
		-isohybrid-mbr $ROOTFS/usr/share/syslinux/isohdpfx.bin \
		-c isolinux/boot.cat \
		-b isolinux/isolinux.bin \
		  -no-emul-boot \
		  -boot-load-size 4 \
		  -boot-info-table \
		-eltorito-alt-boot \
		-e boot/efiboot.img \
		  -no-emul-boot \
		  -isohybrid-gpt-basdat \
		  -volid $ISOLABEL \
		-o "$OUTPUTISO" "$ISODIR" || die "Failed creating iso: $OUTPUTISO"
	
	msg "Cleaning iso directory: $ISODIR"
	rm -fr "$ISODIR"
	md5sum "$OUTPUTISO" > "$OUTPUTISO".md5
	msg "Making iso completed: $OUTPUTISO ($(ls -lh $OUTPUTISO | awk '{print $5}'))"
}

generatelocales() {
	[ -f $ROOTFS/usr/lib/locale/locale-archive ] && return
	mkdir -p $ROOTFS/usr/lib/locale/
	msg "Generate 'en_US' locales..."
	chrootrun localedef -i en_US -f ISO-8859-1 en_US
	chrootrun localedef -i en_US -f UTF-8 en_US.UTF-8
}

check() {
	[ $2 ] || return 0
	command -v $1 >/dev/null || {
		echo "'$1' not found, please install '$2'"
		return 1
	}
}

checktool() {
	if [ "$ISO" ]; then
		check mksquashfs squashfs-tools || err=1
		check xorriso libisoburn || err=1
		if [ ! -d /usr/lib/grub/x86_64-efi/ ]; then
			echo "'grub-efi' files not found"
			err=1
		fi
	fi
	[ "$err" = 1 ] && exit 1
}

usage() {
	cat << EOF
Usage:
  $0 [options]
  
Options:
  -root=<path>          use custom root location (default: $ROOTFS)
  -pkgdir=<path>        use custom packages directory (default: $PKGDIR)
  -srcdir=<path>        use custom sources directory (default: $SRCDIR)
  -outputiso=<*.iso>    use custom name for iso (default: $OUTPUTISO)
  -jobs=<N>             define total cpu want to use (default: $JOBS)
  -pkg=<pkg1,pkg2,...>  define packages to install into rootfs (comma separated)
  -rootfs               create updated rootfs tarball
  -rebase               remove all installed packages in rootfs except 'base'
  -chroot               enter chroot into rootfs
  -sysup                full upgrade rootfs
  -revdep               fix any broken packages in rootfs
  -zap                  remove and re-extract rootfs
  -iso                  make iso from rootfs
  -fetch                fetch latest rootfs tarball
  -ccache               use ccache
  -h|-help              show this help message
      
EOF
exit 0
}

msg() {
	echo "-> $*"
}

msgerr() {
	echo "!> $*"
}

die() {
	[ "$@" ] && msgerr $@
	exit 1
}

parse_opts() {
	while [ "$1" ]; do
		case $1 in
			  -root=*) ROOTFS=${1#*=};;
			-pkgdir=*) PKGDIR=${1#*=};;
			-srcdir=*) SRCDIR=${1#*=};;
			   -pkg=*) PKG=${1#*=};;
		 -outputiso=*) OUTPUTISO=${1#*=};;
			  -jobs=*) JOBS=${1#*=};;
			  -rootfs) RFS=1;;
			  -rebase) REBASE=1;;
			  -chroot) CHROOT=1;;
			   -sysup) SYSUP=1;;
			  -revdep) REVDEP=1;;
			     -zap) ZAP=1;;
			     -iso) ISO=1;;
			   -fetch) FETCH=1;;
			  -ccache) CCACHE=1;;
			 -h|-help) HELP=1;;
			        *) die "invalid options: $1";;
		esac
		shift
	done
}

main() {
	[ "$HELP" ] && usage
	
	checktool

	[ "$(id -u)" = 0 ] || {
		die "$0 need root access!"
	}

	mkdir -p $PKGDIR $SRCDIR $CCACHE_DIR
	
	[ "$FETCH" ] && fetch_rootfs
	
	# check if rootfs already exist, else zap
	check_rootfs
	
	[ "$ZAP" ] && zap_rootfs
	
	generatelocales
	
	[ "$REBASE" ] && {
		msg "Running pkgbase..."
		chrootrun pkgbase -y || die
	}
	
	[ "$SYSUP" ] && {
		msg "Upgrading scratchpkg..."
		chrootrun scratch upgrade scratchpkg -y --no-backup || die
		tmp_scratchpkgconf
		msg "Full upgrading..."
		chrootrun scratch sysup -y --no-backup || die
		[ -f $ROOTFS/etc/venom-release ] && {
			if [ $(cat $ROOTFS/etc/venom-release) != "$RELEASE" ]; then
				msgerr "venom-release $(cat $ROOTFS/etc/venom-release) != $RELEASE"
			fi
		}
	}
	
	[ "$REVDEP" ] && {
		msg "Running revdep (after sysup)..."
		chrootrun revdep -y -r || die
	}
	
	[ "$RFS" ] && {
		compress_rootfs || die
	}
	
	[ "$CCACHE" ] && {
		chrootrun scratch install -y ccache || die
	}
	
	[ "$PKG" ] && {
		chrootrun scratch install -y $(echo $PKG | tr ',' ' ') || die
	}
	
	[ "$CHROOT" ] && {
		msg "Entering chroot..."
		chrootrun /bin/sh || die
	}
	
	[ "$ISO" ] && {
		chrootrun scratch install -y $(echo $ISO_PKG | tr ',' ' ') || die
		[ "$REVDEP" ] && {
			msg "Running revdep (for iso)..."
			chrootrun revdep -y -r || die
		}
		make_iso
	}
	
	return 0
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

parse_opts "$@"

ARCH=$(uname -m)
RELEASE=$(git branch --show-current)

[ "$RELEASE" = master ] && {
	RELEASE=current
}

TARBALLIMG="$PORTSDIR/venomlinux-rootfs-$RELEASE-$ARCH.tar.xz"
SRCDIR="${SRCDIR:-/var/cache/scratchpkg/sources}"
PKGDIR="${PKGDIR:-/var/cache/scratchpkg/packages}"
ROOTFS="${ROOTFS:-$PORTSDIR/rootfs}"
CCACHE_DIR="${CCACHEDIR:-/var/lib/ccache}"
FILESDIR="$PORTSDIR/files"
JOBS="${JOBS:-$(nproc)}"

REPO="main multilib nonfree testing"
REPOFILE="$FILESDIR/scratchpkg.repo"

# iso
ISODIR="${ISODIR:-/tmp/venomiso}"
ISOLABEL="VENOMLIVE_$(date +"%Y%m%d")"
ISO_PKG="linux-lts,dialog,squashfs-tools,grub-efi,btrfs-progs,reiserfsprogs,xfsprogs,syslinux"
OUTPUTISO="${OUTPUTISO:-$PORTSDIR/venomlinux-$RELEASE-$ARCH.iso}"

trap "interrupted" 1 2 3 15

main

exit 0
