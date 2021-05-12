#!/bin/sh

getent group lightdm >/dev/null || groupadd -g 65 lightdm
getent passwd lightdm >/dev/null || useradd -c "Lightdm Daemon" -d /var/lib/lightdm -u 65 -g lightdm -s /bin/false lightdm
