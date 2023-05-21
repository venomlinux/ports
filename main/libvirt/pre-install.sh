#!/bin/sh

if [ -z "`getent group libvirt`" ]; then
	/usr/sbin/groupadd --system libvirt
fi

if [ -z "`getent passwd libvirt`" ]; then
	/usr/sbin/useradd -r -g libvirt -d /etc/libvirt -s /bin/false -c "libvirt service user" libvirt
	/usr/bin/passwd -l libvirt
fi
