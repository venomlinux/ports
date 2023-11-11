# PATH
export PATH="$HOME/.local/bin:/sbin:/usr/sbin:$PATH"

# XDG_RUNTIME_DIR 
unset XDG_RUNTIME_DIR
export XDG_RUNTIME_DIR=$(mktemp -d /tmp/$(id -u)-runtime-dir.XXX)

# Autorun X11/Wayland session in TTY1
 if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
   scratch isinstalled seatd && exec seatd-launch dbus-run-session sway 
   scratch isinstalled xinit && exec startx                                                                           
fi
