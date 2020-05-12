#!/bin/bash -e
#
# script to update ports through chroot environment
#

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

EDITOR=${EDITOR:-vim}

[ "$1" ] || exit 1
[ "$2" ] || exit 1

[ -s $PORTSDIR/$1/spkgbuild ] || {
	echo "Port not exist: $1"
	exit 1
}

# update version
sed -i "/^version=/s/=.*/=$2/" $PORTSDIR/$1/spkgbuild

# change release to 1
sed -i "/^release=/s/=.*/=1/" $PORTSDIR/$1/spkgbuild

rm -f $PORTSDIR/$1/.checksums
rm -f $PORTSDIR/$1/.pkgfiles

while true; do
	cat $PORTSDIR/$1/spkgbuild | more
	echo
	while true; do
		echo -n "[C]ontinue [E]dit [A]bort ? "
		read -n1 input
		echo
		case $input in
			E|e) $EDITOR $PORTSDIR/$1/spkgbuild
				 break 1;;
			A|a) exit 1;;
			C|c) break 2;;
		esac
	done
done

rm -f $PORTSDIR/$1/.pkgfiles
sudo $SCRIPTDIR/ports.sh \
	-pkg=${1##*/} \
	-zap || {
		echo -n "Error occurs. Do you want to revert changes? Y/n "
		read -n1 input
		echo
		case $input in
			N|n) echo "Keep changes.";;
			  *) for f in $(git status -s $PORTSDIR/$1 | awk '{print $2}'); do
					 echo -n "$f: "
					 git checkout $f
				 done;;
		esac
		exit 1
	}

exit 0
