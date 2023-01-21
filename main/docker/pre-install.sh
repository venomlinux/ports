#!/bin/sh

if [ -z "`getent group docker`" ]; then
	/usr/sbin/groupadd --system docker
fi
