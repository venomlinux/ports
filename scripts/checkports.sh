#!/bin/sh

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

cd $PORTSDIR

print_msg() {
	port=$1; shift
	msg=$@
	echo "$port: $msg"
}

check_header() {
	item=$1
	port=$2
	[ -f "$port/spkgbuild" ] || return 0
	grep -q "# $item" $port/spkgbuild && return 0 || return 1
}

repo="musl core multilib nonfree"

for r in $repo; do
	for p in $r/*; do
		for i in description homepage maintainer; do
			check_header $i $p || print_msg $p missing header $i
		done
	done
done
