#!/bin/sh

getent group vboxusers >/dev/null || groupadd vboxusers

sh /var/lib/dkms/buildmodules-vboxhost.sh
