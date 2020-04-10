#!/bin/bash

#
# script to build inside chroot
#

bindmount() {
	mount --bind $1 $2
}

bindumount() {
	while true; do
		mountpoint -q $1 || break
		umount $1 2>/dev/null
	done
}

chrootrun() {
	xchroot $ROOTFS $@
	return $?
}

umount_all() {
	bindumount $ROOTFS/var/cache/scratchpkg/packages
	bindumount $ROOTFS/var/cache/scratchpkg/sources
	
	# mount ports dir
	umount_repo
}

umount_repo() {
	for repo in $REPO; do
		bindumount $ROOTFS/usr/ports/$repo
		rm -rf $ROOTFS/usr/ports/$repo
	done
}

doumount() {
	for m in $(findmnt --list | grep $ROOTFS | awk '{print $1}' | sort | tac); do
		bindumount $m
	done
}

mount_all() {
	# umount all mounted first
	doumount
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
	findmnt --list | grep -q $ROOTFS && {
		msgerr "!! ROOTFS STILL MOUNTED !!"
		exit 1
	}
	[ -f "$TARBALLIMG" ] || {
		msgerr "rootfs not exist: $TARBALLIMG"
		exit 1
	}
	msg "Removing $ROOTFS"
	rm -fr $ROOTFS
	mkdir -p $ROOTFS
	msg "Extracting $TARBALLIMG"
	tar -xf $TARBALLIMG -C $ROOTFS
	unset ZAP
}

pkginstall() {
	[ "$*" ] || exit 1
	error=0
	mount_all
	chrootrun scratch upgrade scratchpkg -y
	chrootrun scratch sysup -y
	chrootrun scratch install -y $@ || error=1
	umount_all
	exit $error
}

install_pkg() {
	local estatus=0
	PKG="$(echo $PKG | tr ',' ' ')"
	mount_all
	chrootrun scratch install -y $PKG || estatus=1
	umount_all
	return $estatus
}

rebase_rootfs() {	
	local estatus=0
	mount_all
	chrootrun pkgbase -y || estatus=1
	umount_all
	return 0
}

revdep_rootfs() {	
	local estatus=0
	mount_all
	chrootrun revdep -y -r || estatus=1
	umount_all
	return $estatus
}

sysup_rootfs() {	
	local estatus=0
	mount_all
	chrootrun scratch upgrade scratchpkg -y || {
		estatus=1
	} && {
		chrootrun scratch sysup -y || estatus=1
	}
	umount_all
	return $estatus
}

compress_rootfs() {
	[ "$MUSL" ] || {
		# revdep on non-musl
		msg "Running revdep..."
		chrootrun revdep -r -y || exit 1
	}
		
	pushd $ROOTFS >/dev/null
	
	[ -f "$TARBALLIMG" ] && {
		msg "Backup current rootfs..."
		mv "$TARBALLIMG" "$TARBALLIMG".bak
	}
	
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

chroot_rootfs() {
	local estatus=0
	mount_all
	chrootrun /bin/sh || estatus=1
	umount_all
	return $estatus
}

check_rootfs() {
	[ -d $ROOTFS/dev ] || zap_rootfs
}

make_iso() {
	ISOLINUX_FILES="chain.c32 isolinux.bin ldlinux.c32 libutil.c32 reboot.c32 vesamenu.c32 libcom32.c32 poweroff.c32"
	# prepare isolinux files
	msg "Preparing isolinux..."
	rm -fr $ISODIR
	mkdir -p $ISODIR/{venom,isolinux,boot}
	for file in $ISOLINUX_FILES; do
		cp /usr/share/syslinux/$file $ISODIR/isolinux
	done
	cp $FILESDIR/splash.png $ISODIR/isolinux
	cp $FILESDIR/isolinux.cfg $ISODIR/isolinux
	[ -d virootfs ] && cp -aR virootfs $ISODIR
	[ -d customize ] && cp -aR customize $ISODIR
	
	# make sfs
	msg "Squashing root filesystem: $ISODIR/venom/venomrootfs.sfs ..."
	mksquashfs $ROOTFS $ISODIR/venom/venomrootfs.sfs \
			-b 1048576 -comp zstd \
			-e $ROOTFS/var/cache/scratchpkg/sources/* \
			-e $ROOTFS/var/cache/scratchpkg/packages/* \
			-e $ROOTFS/var/cache/scratchpkg/work/* \
			-e "*.spkgnew" \
			-e $ROOTFS/tmp/* 2>/dev/null || die "Failed create sfs root filesystem"
			
	cp $ROOTFS/boot/vmlinuz-venom $ISODIR/boot/vmlinuz || die "Failed copying kernel"
	
	sed "s/@ISOLABEL@/$ISOLABEL/g" $FILESDIR/venomiso.hook > $ROOTFS/etc/mkinitramfs.d/venomiso.hook || die "Failed preparing venomiso.hook"
	kernver=$(file $ROOTFS/boot/vmlinuz-venom | cut -d ' ' -f9)
	chrootrun mkinitramfs -k $kernver -a venomiso || die "Failed create initramfs"
	cp $ROOTFS/boot/initrd-venom.img $ISODIR/boot/initrd || die "Failed copying initrd"
	
	msg "Setup UEFI mode..."
	mkdir -p $ISODIR/boot/{grub/{fonts,x86_64-efi},EFI}
	if [ -f /usr/share/grub/unicode.pf2 ];then
		cp /usr/share/grub/unicode.pf2 $ISODIR/boot/grub/fonts
	fi
	if [ -f $ISODIR/isolinux/splash.png ]; then
		cp $ISODIR/isolinux/splash.png $ISODIR/boot/grub/
	fi
	echo "set prefix=/boot/grub" > $ISODIR/boot/grub-early.cfg
	cp -a /usr/lib/grub/x86_64-efi/*.{mod,lst} $ISODIR/boot/grub/x86_64-efi || die "Failed copying efi files"
	cp $FILESDIR/grub.cfg $ISODIR/boot/grub/

	grub-mkimage -c $ISODIR/boot/grub-early.cfg -o $ISODIR/boot/EFI/bootx64.efi -O x86_64-efi -p "" iso9660 normal search search_fs_file
	modprobe loop
	dd if=/dev/zero of=$ISODIR/boot/efiboot.img count=4096
	mkdosfs -n VENOM-UEFI $ISODIR/boot/efiboot.img || die "Failed create mkdosfs image"
	mkdir -p $ISODIR/boot/efiboot
	mount -o loop $ISODIR/boot/efiboot.img $ISODIR/boot/efiboot || die "Failed mount efiboot.img"
	mkdir -p $ISODIR/boot/efiboot/EFI/boot
	cp $ISODIR/boot/EFI/bootx64.efi $ISODIR/boot/efiboot/EFI/boot
	umount -l $ISODIR/boot/efiboot
	rm -fr $ISODIR/boot/efiboot

	# save list packages to iso
	for pkg in base $ADD_PKGS; do
		echo "$pkg" >> $ISODIR/venom/pkglist
	done

	VENOM_OUTPUT=$VENOM_OUTPUT.iso
	msg "Creating iso: $OUTPUTDIR/$VENOM_OUTPUT ..."
	rm -f $VENOM_OUTPUT $VENOM_OUTPUT.md5
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
		-o $OUTPUTDIR/$VENOM_OUTPUT $ISODIR || die "Failed creating iso: $OUTPUTDIR/$VENOM_OUTPUT"
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
	check_rootfs
	[ "$ZAP" ] && zap_rootfs
	[ "$REBASE" ] && rebase_rootfs
	[ "$SYSUP" ] && sysup_rootfs
	[ "$REVDEP" ] && revdep_rootfs
	[ "$RFS" ] && compress_rootfs
	[ "$PKG" ] && {
		install_pkg || exit 1
	}
	[ "$CHROOT" ] && chroot_rootfs
	[ "$ISO" ] && make_iso
	return 0
}

parse_opts "$@"

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

WORKDIR="${WORKDIR:-$PORTSDIR/workdir}"
SRCDIR="${SRCDIR:-$WORKDIR/sources}"

if [ "$MUSL" ]; then
	REPO="musl core extra xorg community testing"
	ROOTFS="${ROOTFS:-$WORKDIR/rootfs-musl}"
	PKGDIR="${PKGDIR:-$WORKDIR/packages-musl}"
	TARBALLIMG="$PORTSDIR/venom-musl-rootfs.tar.xz"
else
	REPO="core extra multilib xorg community testing"
	ROOTFS="${ROOTFS:-$WORKDIR/rootfs}"
	PKGDIR="${PKGDIR:-$WORKDIR/packages}"
	TARBALLIMG="$PORTSDIR/venom-rootfs.tar.xz"
fi

OUTPUTDIR="${OUTPUTDIR:-$PORTSDIR/output}"
ISODIR="${ISODIR:-$WORKDIR/iso}"
FILESDIR="$PORTSDIR/files"

VENOM_OUTPUT=${VENOM_OUTPUT:-venom-$(date +"%Y%m%d")}

ISOLABEL="VENOMLIVE_$(date +"%Y%m%d")"
ISO_PKGS="dialog squashfs-tools grub-efi btrfs-progs reiserfsprogs xfsprogs"

trap "umount_all" 1 2 3 15

mkdir -p $PKGDIR $SRCDIR $OUTPUTDIR $WORKDIR

main

exit 0
