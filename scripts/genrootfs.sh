#!/bin/sh

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

sudo $SCRIPTDIR/build.sh \
		-zap \
                -rebase \
		-rootfs || exit 1

exit 0
