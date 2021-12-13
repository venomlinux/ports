#!/bin/sh

getent group vboxsf >/dev/null || groupadd -r vboxsf
chgrp vboxsf /media
sh /var/lib/dkms/buildmodules-vboxguest.sh
