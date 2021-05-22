#!/bin/sh
#
# script for update REPO file using httpup-repgen
#

PORTREPO="main multilib nonfree testing"
PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

if [ ! $(command -v httpup-repgen) ]; then
	echo "httpup not installed, aborting"
	exit 1
fi

for repo in $PORTREPO; do
	[ -d "$PORTSDIR/$repo" ] || {
		echo "repo not exist: $repo"
		continue
	}
	httpup-repgen "$PORTSDIR/$repo"
done

exit 0
