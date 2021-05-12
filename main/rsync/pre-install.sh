#!/bin/sh

getent group rsyncd >/dev/null || groupadd -g 48 rsyncd
getent passwd rsyncd >/dev/null || useradd -c "rsyncd Daemon" -d /home/rsync -g rsyncd -s /bin/false -u 48 rsyncd
