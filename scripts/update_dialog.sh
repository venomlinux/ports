#!/bin/bash

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

outfile="$SCRIPTDIR/.${0##*/}.list"
updatefail="$SCRIPTDIR/.${0##*/}.fail"
updateok="$SCRIPTDIR/.${0##*/}.ok"

vercomp() {	
	if [ "$1" = "$2" ]; then
		return 0 # same version
	elif [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]; then
		return 1 # $1 lower than $2
	else
		return 2 # $1 higher than $2
	fi
}

notify() {
	command -v notify-send >/dev/null && {
		notify-send "$@"
	}
}

notifyerr() {
	command -v notify-send >/dev/null && {
		notify-send -u critical "$@"
	}
}

if [ ! -f $SCRIPTDIR/.outdate.sh.list ]; then
	echo "'.outdate.sh.list' not exist, please run outdate.sh first."
	exit 1
fi

total=0
for i in $(cat $SCRIPTDIR/.outdate.sh.list | tr ' ' '?'); do
	pkg=$(echo $i | cut -d '?' -f1)
	ver=$(echo $i | cut -d '?' -f2)
	oldver=$(echo $i | cut -d '?' -f3)
	
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
	total=$((total+1))
	input="$input $pkg ${oldver}__=>__${ver} off"
done

dialog --clear --no-mouse --checklist "Port Updates ($total)" 0 0 0 $input 2> $outfile

for pkg in $(cat $outfile); do
	clear
	ver=$(grep -Eo "$pkg .*" $SCRIPTDIR/.outdate.sh.list | awk '{print $2}')
	echo ":: $pkg $ver"
	NOPROMPT=1 $SCRIPTDIR/portupdate.sh $pkg $ver
	if [ $? != 0 ]; then
		echo $pkg >> $updatefail
		f="$f $pkg"
		notifyerr "error build: $pkg $ver"
	else
		echo $pkg >> $updateok
		notify "build ok: $pkg $ver"
	fi
done

if [ "$f" ]; then
	echo "build failed:"
	for i in $f; do
		echo " $i"
	done
fi

exit
