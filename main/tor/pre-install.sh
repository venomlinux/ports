#!/bin/sh

getent group tor >/dev/null || groupadd -g 43 tor
getent passwd tor >/dev/null || useradd -c "Anonymizing Overlay Network" -d /var/lib/tor -u 43 -g tor -s /bin/false tor
