#!/bin/sh

getent group sddm >/dev/null || groupadd -g 64 sddm
getent passwd sddm >/dev/null || useradd -c "SDDM Daemon" -d /var/lib/sddm -u 64 -g sddm -s /bin/false sddm
