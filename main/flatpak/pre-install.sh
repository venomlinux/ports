#!/bin/sh

getent group _flatpak >/dev/null || groupadd _flatpak
