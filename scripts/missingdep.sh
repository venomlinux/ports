#!/bin/sh

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"
BUILD_SCRIPT=spkgbuild

repo="main multilib nonfree"

cd $PORTSDIR
rm -f scripts/allports
for r in $repo; do
	for p in $r/*; do
		[ -f $p/spkgbuild ] || continue
		echo ${p##*/} >> scripts/allports
	done
done

for i in core/* multilib/* nonfree/*; do
	[ -f $i/spkgbuild ] || continue
	deps=$(grep "^# depends[[:blank:]]*:" $i/$BUILD_SCRIPT \
	| sed 's/^# depends[[:blank:]]*:[[:blank:]]*//' \
	| tr ' ' '\n' \
	| awk '!a[$0]++' \
	| sed 's/,//'\
	| tr '\n' ' ')
	[ "$deps" ] || continue
	for d in $deps; do
		grep -qx $d scripts/allports || echo "$i: $d"
	done
done

rm -f scripts/allports
