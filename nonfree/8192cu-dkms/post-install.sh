#/bin/sh
depmod -a
rmmod rtl8192cu rtl_usb rtl8192c_common rtlwifi
modprobe 8192cu
