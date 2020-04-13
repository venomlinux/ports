#!/bin/bash

#
# This script is executed inside initramfs using chroot to live environment
#

USER=venom
PASSWORD=venom

useradd -m -G users,wheel,audio,video -s /bin/bash $USER
passwd -d $USER &>/dev/null
passwd -d root &>/dev/null

echo "root:root" | chpasswd -c SHA512
echo "$USER:$PASSWORD" | chpasswd -c SHA512

#chmod -R 775 /home/$USER/.config

sed 's/#\(en_US\.UTF-8\)/\1/' -i /etc/locales
genlocales &>/dev/null

# Enable sudo permission by default.
if [ -f /etc/sudoers ]; then
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

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

mkdir -p /var/lib/lxdm/
cat > /var/lib/lxdm/lxdm.conf <<_EOF
[base]
last_session=__default__
last_lang=
_EOF

#sed -i "s/--noclear/--noclear -a $USER/" /etc/inittab

if [ $(type -p startxfce4) ]; then
	SSN=$(type -p startxfce4)
	SESSION=xfce
elif [ $(type -p mate-session) ]; then
	SSN=$(type -p mate-session)
	SESSION=mate
elif [ $(type -p startlxqt) ]; then
	SSN=$(type -p startlxqt)
	SESSION=lxqt
elif [ $(type -p startlxde) ]; then
	SSN=$(type -p startlxde)
	SESSION=LXDE
elif [ $(type -p jwm) ]; then
	SSN=$(type -p jwm)
	SESSION=jwm
elif [ $(type -p openbox) ]; then
	SSN=$(type -p openbox)
	SESSION=openbox
fi

if [ -x $(type -p lxdm) ]; then
	sed -e "s,.*session.*=.*,session=$SSN," -i /etc/lxdm/lxdm.conf
	sed -e "s,.*autologin.*=.*,autologin=$USER," -i /etc/lxdm/lxdm.conf
elif [ -x $(type -p lightdm) ]; then
	sed -i "s/#autologin-user=/autologin-user=$USER/" /etc/lightdm/lightdm.conf
	sed -i "s/#autologin-session=/autologin-session=mate/" /etc/lightdm/lightdm.conf
elif [ -x $(type -p sddm) ]; then
	mkdir -p /etc/sddm.conf.d/
	cat > /etc/sddm.conf.d/autologin.conf <<_EOF
[Autologin]
User=$USER
Session=$SESSION.desktop
_EOF
fi

echo venomlive > /etc/hostname

if [ -d /etc/sv/lxdm ]; then
	DM=lxdm
elif [ -d /etc/sv/lightdm ]; then
	DM=lightdm
elif [ -d /etc/sv/sddm ]; then
	DM=sddm
elif [ -d /etc/sv/slim ]; then
	DM=slim
fi

if [ -d /etc/sv/networkmanager ]; then
	NETWORK=networkmanager
elif [ -d /etc/sv/dhcpcd ]; then
	NETWORK=dhcpcd
fi

for i in sysklogd dbus $DM $NETWORK bluetooth; do
	if [ -d /etc/sv/$i ]; then
		ln -sf /etc/sv/$i /var/service
	fi
done

exit 0
