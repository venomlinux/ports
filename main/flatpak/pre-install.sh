#!/bin/sh

getent passwd _flatpak >/dev/null || useradd -N -r -s /sbin/nologin -d /var/empty _flatpak
