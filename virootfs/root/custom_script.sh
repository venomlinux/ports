#!/bin/sh

#
# This script is executed inside initramfs using chroot to live environment
#

LIVEUSER=venom
PASSWORD=venom

useradd -m -G users,wheel,audio,video -s /bin/bash $LIVEUSER
#passwd -d $LIVEUSER &>/dev/null
#passwd -d root &>/dev/null

echo "root:$PASSWORD" | chpasswd -c YESCRYPT
echo "$LIVEUSER:$PASSWORD" | chpasswd -c YESCRYPT

# generate en_US locale
sed 's/#\(en_US\.UTF-8\)/\1/' -i /etc/locales
genlocales &>/dev/null

# hostname for live
echo venomlive > /etc/hostname

# enable sudo permission for all user in live
if [ -f /etc/sudoers ]; then
    echo "$LIVEUSER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# allow polkit for wheel group in live
if [ -d /etc/polkit-1 ]; then
    cat > /etc/polkit-1/rules.d/venom-live.rules <<_EOF
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:wheel"];
});
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
_EOF
fi

# change slim theme
[ -d /usr/share/slim/themes/greeny_dark ] && {
	sed "s/current_theme.*/current_theme greeny_dark/" -i /etc/slim.conf
}

# slim autologin
sed "s/#default_user.*/default_user $LIVEUSER/" -i /etc/slim.conf
sed "s/#auto_login.*/auto_login yes/" -i /etc/slim.conf

# network
if [ -x /etc/rc.d/networkmanager ] || [ -d /etc/sv/networkmanager ]; then
	NETWORK=networkmanager
elif [ -x /etc/rc.d/network ]; then
	NETWORK=network
fi

for i in sysklogd dbus $NETWORK bluetooth; do
	if [ -x /etc/rc.d/$i ]; then
		daemon="$daemon $i"
	fi
	if [ -d /etc/sv/$i ]; then
		ln -s /etc/sv/$i /var/service
	fi
done

sed -i "s/^#DAEMONS=.*/DAEMONS=\"$daemon\"/" /etc/rc.conf

exit 0
