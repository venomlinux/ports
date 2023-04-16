#!/bin/sh -e

_USER=avahi
_HOME=/run/avahi
_GROUP=avahi

getent group $_GROUP > /dev/null 2>&1 || groupadd $_GROUP
getent passwd $_USER > /dev/null 2>&1 || useradd -c 'avahi system user' -g $_GROUP -d $_HOME -s /bin/false $_USER
passwd -l $_USER > /dev/null
