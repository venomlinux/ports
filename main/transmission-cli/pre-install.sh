#!/bin/sh

getent group transmission >/dev/null || groupadd -g 169 transmission
getent passwd transmission >/dev/null || useradd -c "Transmission BitTorrent Daemon" -d /var/lib/transmission -u 169 -g transmission -s /bin/false transmission
