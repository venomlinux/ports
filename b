#!/bin/sh

msg() {
	echo ">> $@"
	notify-send "$@"
}

touch done
touch base

for i in $(cat order); do
	case $i in
		atril) continue;;
	esac
	grep -qx $i base && {
		msg "part of base: $i"
		continue
	}
	grep -qx $i done && {
		msg "skip done: $i"
		continue
	}
	msg "start build: $i"
	sudo ./scripts/build.sh -zap -pkg=$i || {
		msg "failed build: $i"
		exit 1
	}
	echo $i >> done
done
	
exit 0
