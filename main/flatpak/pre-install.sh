#!/bin/sh

getent group _flatpak >/dev/null || useradd -r _flatpak
