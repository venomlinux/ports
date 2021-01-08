#!/bin/sh

msg() {
	echo "$port: $@"
}

verifyvar() {
	for i in backup noextract options source; do
		grep -q ${i}=\"\" $portpath/spkgbuild && msg "please remove this empty variable: ${i}=\"\""
	done
}

verifyfiles() {
	[ -f $portpath/.pkgfiles ] || msg "'.pkgfiles' not exist, please generate it using 'pkgbuild -p'"
	[ -f $portpath/.checksums ] || msg "'.checksums' not exist, please generate it using 'pkgbuild -g'"
}

verifyunnecessaryfiles() {
	if [ -f $portpath/.pkgfiles ]; then
		grep -q "usr/share/licenses" $portpath/.pkgfiles && msg "please remove licenses: usr/share/licenses"
	fi
}

verifythisisnotcrux() {
	for i in PKGMK prt prt-get; do
		grep -q "$i" $portpath/spkgbuild && msg "please remove CRUX stuff, this is not CRUX"
	done
}

verifydeps() {
	deps=
	if [ "$(grep "^# depends[[:blank:]]*:" $portpath/spkgbuild)" ]; then
		deps=$(grep "^# depends[[:blank:]]*:" $portpath/spkgbuild \
			| sed 's/^# depends[[:blank:]]*:[[:blank:]]*//' \
			| tr ' ' '\n' \
			| awk '!a[$0]++' \
			| sed 's/,//')
		[ "$deps" ] || msg "empty dependency"
		cd $PORTSDIR
		for d in $deps; do
			found=0
			for r in core multilib nonfree; do
				if [ -f $r/$d/spkgbuild ]; then
					found=1
					break
				fi
			done
			if [ "$found" = 0 ]; then
				msg "dependency '$d' not exist in repo"
			fi
		done
		cd - >/dev/null
	fi
}

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

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
	verifyunnecessaryfiles
	verifythisisnotcrux
	shift
done

exit 0
