#!/bin/sh

getent group apache >/dev/null || groupadd -g 25 apache
getent passwd apache >/dev/null || useradd -c "Apache Server" -d /srv/www -g apache -s /bin/false -u 25 apache
