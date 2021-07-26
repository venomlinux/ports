#!/bin/bash

get_portpath() {
	local port=$1
	
	if [ -z "$port" ]; then
		echo "Please define port name."
		exit 2
	fi
	
	for r in ${PORTREPO[@]}; do
		if [ -f $r/$port/spkgbuild ]; then
			portpath=$r/$port
			break
		fi
	done
	
	if [ -z "$portpath" ]; then
		echo "Port '$port' not exist."
		exit 1
	fi
}

revert_changes() {
	local revert
	local opt=$1
	
	if [ "$opt" != "-y" ]; then
		echo -n "Error occurs. Do you want to revert changes? Y/n "
		read -n1 input
		echo
	else
		input=y
	fi
	
	case $input in
		N|n) echo "Keep changes.";;
		  *) for f in $(git status -s . | awk '{print $2}'); do
				echo -n "$f: "
				git checkout $f
			 done;;
	esac
	exit 4
}

isinstalled() {
	if [ -s $INDEX_DIR/$1/.pkginfo ] && [[ $(grep $1 $INDEX_DIR/$1/.pkginfo) ]]; then
		return 0
	else
		return 1
	fi
}

get_depends() {	
	[ -f $portpath/spkgbuild ] || return 0
	grep "^# depends[[:blank:]]*:" $portpath/spkgbuild \
	| sed 's/^# depends[[:blank:]]*:[[:blank:]]*//' \
	| tr ' ' '\n' \
	| awk '!a[$0]++' \
	| sed 's/,//'
}

check_dep() {
	deps=$(get_depends)
	for d in $deps; do
		found=0
		if ! isinstalled $d; then
			echo "Dependency not installed: $d"
			msdep=1
			for r in ${PORTREPO[@]}; do
				if [ -f "$r/$d/spkgbuild" ]; then
					found=1
					break
				fi
			done
			if [ "$found" != 1 ]; then
				echo "Missing dependency port: $d"
			fi
		fi
	done
	
	[ "$msdep" = 1 ] && exit 1
}

port_update() {
	local portpath=$1
	local vers=$2
	local opt=$3
	
	[ -f "$portpath/spkgbuild" ] || {
		echo "Port '$portpath' not exist"
		exit 2
	}
	
	[ "$vers" ] || {
		echo "Please define version to update."
		exit 2
	}
	
	check_dep
	
	pushd $portpath >/dev/null
	
	# update version
	sed -i "/^version=/s/=.*/=$vers/" spkgbuild
	
	# change release to 1
	sed -i "/^release=/s/=.*/=1/" spkgbuild
	
	if [ "$opt" != "-y" ]; then
		while true; do
		cat spkgbuild | more
		echo
		
			while true; do
				echo -n "[C]ontinue [E]dit [A]bort ? "
				read -n1 input
				echo
				case $input in
					E|e) $EDITOR spkgbuild
						 break 1;;
					A|a) exit 1;;
					C|c) break 2;;
				esac
			done
		done
	fi		
	
	fakeroot pkgbuild -o || revert_changes "$opt"
	fakeroot pkgbuild -g || revert_changes "$opt"
	fakeroot pkgbuild    || revert_changes "$opt"
	fakeroot pkgbuild -p || revert_changes "$opt"
	sudo pkgbuild -u -v  && sudo scratch trigger ${portpath#*/}
	
	popd >/dev/null
}

port_build() {
	local port=$1; shift
	opt=$@
	
	for i in $opt; do
		if [[ $i =~ -(i|u|r) ]]; then
			continue # filter out install/upgrade/reinstall
		else
			opts+=" $i"
		fi
	done
	
	get_portpath $port
	
	check_dep
	
	pushd $portpath >/dev/null
	
	while true; do
	cat spkgbuild | more
	echo
	
		while true; do
			echo -n "[E]dit [A]bort [C]ontinue ? "
			read -n1 input
			echo
			case $input in
				E|e) $EDITOR spkgbuild
				     break 1;;
				A|a) exit 1;;
				C|c) break 2;;
			esac
		done
	done			
	
	fakeroot pkgbuild $opts || return $?
	
	popd >/dev/null
}

port_commit() {
	local port=$1; shift
	cmsg=$@
	
	if [ -z "$port" ]; then
		for p in $(git status -s ${PORTREPO[@]} | awk '{print $2}' | cut -d / -f -2 | uniq); do
			case $p in
				*/REPO) continue;;
			esac
			git diff --name-only ${PORTREPO[@]} | grep -q ^$p/ || cmsg="new port"
			commit_port $p
		done
	else
		[ -f "$port/spkgbuild" ] || {
			echo "Port '$port' not exist"
			exit 1
		}
		
		git status -s ${PORTREPO[@]} | awk '{print $2}' | cut -d / -f -2 | uniq | grep -qx $port || {
			echo "Nothing to commit for '$port'"
			exit 1
		}
		git diff --name-only ${PORTREPO[@]} | grep -q ^$port/ || cmsg="new port"
		commit_port $port
	fi	
}

commit_port() {
	local portpath=$1
	
	deps=$(get_depends)
	for d in $deps; do
		found=0
		for r in ${PORTREPO[@]}; do
			if [ -f "$r/$d/spkgbuild" ]; then
				found=1
				break
			fi
		done
		if [ "$found" != 1 ]; then
			echo "$portpath: Missing dependency '$d'"
			missing=1
		fi
	done
	
	[ "$missing" = 1 ] && exit 1
	
	if [ ! -f $portpath/.pkgfiles ]; then
		echo "$portpath: Please generate .pkgfiles first"
		exit 1
	fi
	
	if [ ! -f $portpath/.checksums ]; then
		echo "$portpath: Please generate .checksums first"
		exit 1
	fi
	
	if [ -z "$cmsg" ]; then
		if [ -f $portpath/spkgbuild ]; then
			. $portpath/spkgbuild
			cmsg="updated to $version"
		else
			cmsg="port removed"
		fi
	fi
	
	git add $portpath
	git commit -m "$portpath: $cmsg"
	
	unset cmsg
}

port_push() {
	#if git status | grep "Your branch is up to date"; then
	#	return 0
	#fi
	
	if git diff --name-only ${PORTREPO[@]} | grep -v REPO; then
		echo
		echo "Please commit above changes first."
		return 2
	fi
	
	#echo "generating packagelist"
	#$SCRIPTDIR/genpackagelist.sh
	
	#git add $SCRIPTDIR/packages.json
	
	for r in ${PORTREPO[@]}; do
		git add $r
	done
	
	#git commit -m "REPO updated"
	git push
}

port_diff() {
	local port=$1
	
	get_portpath $port
	
	pushd $portpath >/dev/null

	git diff .
	
	popd >/dev/null
}

port_status() {
	git status -s
	#git status | grep "Your branch is ahead of" && echo
	#git status | grep -v REPO | grep modified | sed 's/.*modified:/modified:/g'
}

port_checkdep() {
	for r in ${PORTREPO[@]}; do
		tmprepo="$tmprepo $r"
		for p in $r/*/spkgbuild; do
			portpath=$(dirname $p)
			for d in $(get_depends); do
				found=0
				for tp in $tmprepo; do
					if [ -f $tp/$d/spkgbuild ]; then
						found=1
						break
					fi
				done
				[ "$found" = 0 ] && echo "$portpath: $d"
			done
		done
	done
}

port_revert() {
	local port=$1
	[ "$port" ] || return 1
	if [ ! -d $PORTSDIR/$port ]; then
		echo "port '$port' not exist"
		exit 1
	fi
	for f in $(git status -s $PORTSDIR/$port | awk '{print $2}'); do
		echo -n "$f: "
		git checkout $f
	done
}

port_help() {
	cat << EOF
Usage:
  ./$(basename $0) <options> [ arg ]
  
Options:
  update <portname> <newversion>   update ports to <newversion>
  commit <portname> <commit msg>   commit port's update changes
  build  <portname> <opts>         build port
  diff   <portname>                show diff of ports
  revert <portname>                revert ports changes
  repgen                           update REPO file
  push                             push all updates
  status                           show current status
  help                             show this help message
      
EOF
}

PORTREPO=(main multilib nonfree testing)
INDEX_DIR="/var/lib/scratchpkg/index"
EDITOR=${EDITOR:-vim}
PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

OP=$1
shift

if [ $(type -t port_$OP) ]; then
	cd $PORTSDIR
	port_$OP $@
else
	port_help
	exit 1
fi

exit $?
