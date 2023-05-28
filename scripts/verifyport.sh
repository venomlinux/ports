#!/bin/bash

msg() {
	echo "$port: $@"
}

getdeps() {
	# getdeps <portpath>
	grep "^# depends[[:blank:]]*:" $portpath/spkgbuild \
	| sed 's/^# depends[[:blank:]]*:[[:blank:]]*//' \
	| tr ' ' '\n' \
	| awk '!a[$0]++' \
	| sed 's/,//'
}

verifyvar() {
	for i in backup noextract source; do
		grep -q ${i}=\"\" $portpath/spkgbuild && msg "please remove this empty variable: ${i}=\"\""
	done
}

verifyfiles() {
	[ -f $portpath/.pkgfiles ] || msg "'.pkgfiles' not exist, please generate it using 'pkgbuild -p'"
	[ -f $portpath/.checksums ] || msg "'.checksums' not exist, please generate it using 'pkgbuild -g'"
}

verifythisisnotcrux() {
	for i in PKGMK prt prt-get; do
		grep -q "$i" $portpath/spkgbuild && msg "please remove CRUX stuff, this is not CRUX"
	done
}

verifythisisnotarch() {
	for i in pkgver pkgrel pkgdesc pkgdir srcdir; do
		grep -q "$i" $portpath/spkgbuild && msg "please remove ARCH stuff, this is not ARCH"
	done
}

verifyforbiddendir() {
	[ -f $portpath/.pkgfiles ] || return
	for i in \
		usr/share/licenses/ \
		usr/share/locale/ \
		usr/share/doc/ \
		usr/share/gtk-doc/ \
		usr/doc/ \
		usr/locale; do
		grep -q ${i}$ $portpath/.pkgfiles && msg "please remove this forbidden directory: ${i}"
	done
}

verifynotusedir() {
	[ -f $portpath/.pkgfiles ] || return
	for i in \
		usr/local/ \
		usr/etc/ \
		usr/libexec/; do
		grep -q ${i}$ $portpath/.pkgfiles && msg "this directory not use in venom: ${i}"
	done
}

verifydeps() {
	if [ "$(grep "^# depends[[:blank:]]*:" $portpath/spkgbuild)" ]; then
		deps=$(getdeps)
		[ "$deps" ] || {
			msg "empty dependency"
			return
		}
		for d in $deps; do
			found=0
			for r in $REPO; do
				[ -f $PORTSDIR/$r/$d/spkgbuild ] && {
					found=1
					break
				}
			done
			[ $found = 0 ] && msg "missing deps '$d'"
		done
	fi
}

verifypkgfiles() {
	[ -f $portpath/.pkgfiles ] || return
	. $portpath/spkgbuild
	[ "$name-$version-$release" = "$(head -n1 $portpath/.pkgfiles)" ] || {
		msg "looks like .pkgfiles outdated please regenerate .pkgfiles using 'pkgbuild -p'"
	}
}

runverify() {
	while [ $1 ]; do
		portpath="$(realpath $1)"
		port=${portpath##*/}
		[ -f $portpath/spkgbuild ] || {
			msg "looks like not a valid port"
			shift; continue
		}
		verifydeps
		verifyvar
		verifyfiles
		verifythisisnotcrux
		verifythisisnotarch
		verifyforbiddendir
		verifynotusedir
		verifypkgfiles
		shift
	done
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"
REPO="core main multilib nonfree"

if [ $1 ]; then
	runverify $@
else
	for r in $REPO; do
		runverify $PORTSDIR/$r/*
	done
fi

exit 0
