#!/bin/sh

getent group nginx >/dev/null || groupadd -g 26 nginx
getent passwd nginx >/dev/null || useradd -c "Nginx Server" -d /var/www -g nginx -s /bin/false -u 26 nginx
