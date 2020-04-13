#!/bin/bash
#
# script to build inside chroot
#

interrupted() {
	unmount_any_mounted
	exit 1
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
	cp -L /etc/resolv.conf $ROOTFS/etc/
	chroot $ROOTFS $@
	retval=$?
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

zap_rootfs() {
	unmount_any_mounted
	
	[ -f "$TARBALLIMG" ] || {
		msgerr "Tarball img not exist: $TARBALLIMG"
		exit 1
	}
	msg "Removing existing rootfs: $ROOTFS"
	rm -fr $ROOTFS
	mkdir -p $ROOTFS
	msg "Extracting tarball image: $TARBALLIMG"
	tar -xf $TARBALLIMG -C $ROOTFS
	cp $FILESDIR/$REPOFILE $ROOTFS/etc/scratchpkg.repo
	unset ZAP
}

install_pkg() {
	local estatus=0
	PKG="$(echo $PKG | tr ',' ' ')"
	chrootrun scratch install -y $PKG || estatus=1
	return $estatus
}

compress_rootfs() {
	# fix broken packages before compress rootfs
	msg "Running revdep..."
	chrootrun revdep -y -r || exit 1

	pushd $ROOTFS >/dev/null
	
	[ -f "$TARBALLIMG" ] && {
		msg "Backup current rootfs..."
		mv "$TARBALLIMG" "$TARBALLIMG".bak
	}
	
	msg "Copying ports..."
	copy_ports
	
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
	if [ ! "$MUSL" ] && [ -e $ROOTFS/lib/ld-musl-x86_64.so.1 ]; then
		echo "rootfs directory is pointed to musl, please use '-musl' for musl rootfs"
		exit 1
	fi
	# musl and glibc packages must separated
	if [ "$MUSL" ]; then
		if [ -f "$PKGDIR/packages.glibc" ]; then
			msg "Looks like PKGDIR is pointed to non-musl packages directory"
			exit 1
		elif [ ! -f "$PKGDIR/packages.musl" ]; then
			echo "musl packages" > "$PKGDIR/packages.musl"
		fi
	else
		if [ -f "$PKGDIR/packages.musl" ]; then
			msg "Looks like PKGDIR is pointed to musl packages directory"
			exit 1
		elif [ ! -f "$PKGDIR/packages.glibc" ]; then
			echo "glibc packages" > "$PKGDIR/packages.glibc"
		fi
	fi
}

copy_ports() {
	for repo in $REPO; do
		[ -d $PORTSDIR/$repo ] || msg "Repo not exist: $repo"
		msg "Copying repo: $repo"
		cp -Ra $PORTSDIR/$repo $ROOTFS/usr/ports || exit 1
		rm -f $ROOTFS/usr/ports/$repo/REPO
		rm -f $ROOTFS/usr/ports/$repo/.httpup-repgen-ignore
		rm -f $ROOTFS/usr/ports/$repo/*/update
		chown -R 0:0 $ROOTFS/usr/ports/$repo
	done
}

make_iso() {
	ISOLINUX_FILES="chain.c32 isolinux.bin ldlinux.c32 libutil.c32 reboot.c32 vesamenu.c32 libcom32.c32 poweroff.c32"
	# prepare isolinux files
	msg "Preparing isolinux..."
	rm -fr "$ISODIR"
	mkdir -p "$ISODIR"/{venom,isolinux,boot}
	for file in $ISOLINUX_FILES; do
		cp "/usr/share/syslinux/$file" "$ISODIR/isolinux" || die "Failed copying isolinux file: $file"
	done
	cp "$FILESDIR/splash.png" "$ISODIR/isolinux"
	cp "$FILESDIR/isolinux.cfg" "$ISODIR/isolinux"
	
	[ -d "$PORTSDIR/virootfs" ] && {
		cp -aR "$PORTSDIR/virootfs" "$ISODIR"
		chown -R 0:0 "$ISODIR/virootfs"
	}
	[ -d "$PORTSDIR/customize" ] && {
		cp -aR "$PORTSDIR/customize" "$ISODIR"
		chown -R 0:0 "$ISODIR/customize"
	}
	
	copy_ports
	
	# make sfs
	msg "Squashing root filesystem: $ISODIR/venom/venomrootfs.sfs ..."
	mksquashfs "$ROOTFS" "$ISODIR/venom/venomrootfs.sfs" \
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
	mkdir -p "$ISODIR"/boot/{grub/{fonts,x86_64-efi},EFI}
	if [ -f /usr/share/grub/unicode.pf2 ];then
		cp "/usr/share/grub/unicode.pf2" "$ISODIR/boot/grub/fonts"
	fi
	if [ -f "$ISODIR/isolinux/splash.png" ]; then
		cp "$ISODIR/isolinux/splash.png" "$ISODIR/boot/grub/"
	fi
	echo "set prefix=/boot/grub" > "$ISODIR/boot/grub-early.cfg"
	cp -a /usr/lib/grub/x86_64-efi/*.{mod,lst} "$ISODIR/boot/grub/x86_64-efi" || die "Failed copying efi files"
	cp "$FILESDIR/grub.cfg" "$ISODIR/boot/grub/"

	grub-mkimage -c "$ISODIR/boot/grub-early.cfg" -o "$ISODIR/boot/EFI/bootx64.efi" -O x86_64-efi -p "" iso9660 normal search search_fs_file
	modprobe loop
	dd if=/dev/zero of=$ISODIR/boot/efiboot.img count=4096
	mkdosfs -n VENOM-UEFI "$ISODIR/boot/efiboot.img" || die "Failed create mkdosfs image"
	mkdir -p "$ISODIR/boot/efiboot"
	mount -o loop "$ISODIR/boot/efiboot.img" "$ISODIR/boot/efiboot" || die "Failed mount efiboot.img"
	mkdir -p "$ISODIR/boot/efiboot/EFI/boot"
	cp "$ISODIR/boot/EFI/bootx64.efi" "$ISODIR/boot/efiboot/EFI/boot"
	unmount "$ISODIR/boot/efiboot"
	rm -fr "$ISODIR/boot/efiboot"

	# save list packages to iso
	for pkg in base $ADD_PKGS; do
		echo "$pkg" >> "$ISODIR/venom/pkglist"
	done

	msg "Making iso: $OUTPUTISO ..."
	rm -f "$OUTPUTISO" "$OUTPUTISO.md5"
	xorriso -as mkisofs \
		-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
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
}

msg() {
	echo "-> $*"
}

msgerr() {
	echo "!> $*"
}

die() {
	[ "$@" ] && msg $@
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
			  -rootfs) RFS=1;;
			  -rebase) REBASE=1;;
			  -chroot) CHROOT=1;;
			  -umount) UMOUNT=1;;
			   -sysup) SYSUP=1;;
			  -revdep) REVDEP=1;;
			     -zap) ZAP=1;;
			     -iso) ISO=1;;
			    -musl) MUSL=1;;
			        *) msgerr "invalid options: $1"; exit 1;;
		esac
		shift
	done
}

main() {
	# check if rootfs already exist, else zap
	check_rootfs
	
	[ "$ZAP" ] && zap_rootfs
	
	[ "$REBASE" ] && {
		msg "Running pkgbase..."
		chrootrun pkgbase -y || exit 1
	}
	
	[ "$SYSUP" ] && {
		msg "Upgrading scratchpkg..."
		chrootrun scratch upgrade scratchpkg -y || exit 1
		cp $FILESDIR/$REPOFILE $ROOTFS/etc/scratchpkg.repo
		msg "Full upgrading..."
		chrootrun scratch sysup -y || exit 1
	}
	
	[ "$REVDEP" ] && {
		msg "Running revdep (1st)..."
		chrootrun revdep -y -r || exit 1
	}
	
	[ "$RFS" ] && {
		compress_rootfs || exit 1
	}
	
	[ "$PKG" ] && {
		install_pkg || exit 1
		[ "$REVDEP" ] && {
			msg "Running revdep (2nd)..."
			chrootrun revdep -y -r || exit 1
		}
	}
	
	[ "$CHROOT" ] && {
		mount_cache_and_portsrepo
		msg "Entering chroot..."
		chrootrun /bin/sh || exit 1
		umount_cache_and_portsrepo
	}
	
	[ "$ISO" ] && {
		PKG=$ISO_PKG
		install_pkg
		[ "$REVDEP" ] && {
			msg "Running revdep (3rd)..."
			chrootrun revdep -y -r || exit 1
		}
		make_iso
	}
	
	return 0
}

parse_opts "$@"

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

WORKDIR="${WORKDIR:-$PORTSDIR/workdir}"
SRCDIR="${SRCDIR:-$WORKDIR/sources}"
ISODIR="${ISODIR:-$WORKDIR/iso}"
FILESDIR="$PORTSDIR/files"
ISOLABEL="VENOMLIVE_$(date +"%Y%m%d")"
ISO_PKG="linux,dialog,squashfs-tools,grub-efi,btrfs-progs,reiserfsprogs,xfsprogs,$PKG"

if [ "$MUSL" ]; then
	REPO="musl core"
	ROOTFS="${ROOTFS:-$WORKDIR/rootfs-musl}"
	PKGDIR="${PKGDIR:-$WORKDIR/packages-musl}"
	TARBALLIMG="$PORTSDIR/venom-musl-rootfs.tar.xz"
	REPOFILE="scratchpkg-musl.repo"
	OUTPUTISO="${OUTPUTISO:-$PORTSDIR/venom-musl-$(date +"%Y%m%d").iso}"
else
	REPO="core multilib"
	ROOTFS="${ROOTFS:-$WORKDIR/rootfs}"
	PKGDIR="${PKGDIR:-$WORKDIR/packages}"
	TARBALLIMG="$PORTSDIR/venom-rootfs.tar.xz"
	REPOFILE="scratchpkg.repo"
	OUTPUTISO="${OUTPUTISO:-$PORTSDIR/venom-$(date +"%Y%m%d").iso}"
fi

trap "interrupted" 1 2 3 15

mkdir -p $PKGDIR $SRCDIR $WORKDIR

main

exit 0
