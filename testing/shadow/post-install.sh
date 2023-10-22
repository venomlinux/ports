#!/bin/sh

if [ -x usr/sbin/pwconv -a -x usr/sbin/grpconv ]; then
	pwconv && grpconv
fi
