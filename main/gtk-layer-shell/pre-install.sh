#!/bin/sh
[ -f "/usr/include/gtk-3.0/gdk/gdkwayland.h" ]  || \
(printf "gtk3 is missing wayland libraries, rebuilding gtk3...\n" ; scratch install -fr gtk3)
