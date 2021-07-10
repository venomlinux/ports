#!/bin/bash

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

updatefail="$SCRIPTDIR/update.fail"
updateskip="$SCRIPTDIR/update.skip"

vercomp() {	
	if [ "$1" = "$2" ]; then
		return 0 # same version
	elif [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]; then
		return 1 # $1 lower than $2
	else
		return 2 # $1 higher than $2
	fi
}

if [ ! -f $SCRIPTDIR/outdate.list ]; then
	echo "outdate.list file not found"
	exit 1
fi

for i in $(cat $SCRIPTDIR/outdate.list | tr ' ' '?'); do
	pkg=$(echo $i | cut -d '?' -f1)
	ver=$(echo $i | cut -d '?' -f2)
	oldver=$(echo $i | cut -d '?' -f3)
	
	case $pkg in
		*/python2-*) continue;;
	esac
	
	[ -s $PORTSDIR/$pkg/spkgbuild ] || {
		echo "Port not exist: $pkg"
		continue
	}
	pver=$(grep ^version= $PORTSDIR/$pkg/spkgbuild | cut -d = -f2)
	unset vc
	vercomp $ver $pver # $1 = oldver $2 = newver
	vc=$?
	if [ "$vc" = 0 ] || [ "$vc" = 1 ]; then
		continue
	fi
	if [ -f $updateskip ]; then
		grep -qw $pkg $updateskip && continue
	fi
	clear
	skip=0
	while true; do
		#sed "/^version=/s/=.*/=$ver/" $PORTSDIR/$pkg/spkgbuild | diff --color $PORTSDIR/$pkg/spkgbuild -
		echo -n "$pkg => $ver ($pver) | [C]ontinue [S]kip ? "
		read -n1 input
		echo
		case $input in
			S|s) skip=1; break;;
			C|c) skip=0; break;;
		esac
	done
	
	if [ "$skip" = 1 ]; then
		echo "$pkg $ver ($oldver)" >> $updateskip
		continue
	fi
	$SCRIPTDIR/portupdate.sh $pkg $ver
	if [ $? != 0 ]; then
		echo $pkg >> $updatefail
	fi
done
	
exit 0

