#!/bin/sh
# script to generate packages.json

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

repo="core multilib nonfree testing"

echo -ne "[" > packages.json

for r in $repo; do
	for p in $PORTSDIR/$r/*; do
		[ -f $p/spkgbuild ] || continue
		. $p/spkgbuild
		jsonformat="{\"name\": "\"$name"\",\"version\": "\"$version"\",\"release\": "\"$release"\",\"repo\": "\"$r"\"},"
		echo -ne $jsonformat >> packages.json
	done
done

sed 's/.$//' -i packages.json # remove last comma (,)
echo -ne "]" >> packages.json

exit 0
