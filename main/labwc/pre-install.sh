#! /bin/sh

# This version of labwc uses wlroots 0.17, so we check if version 0.16 is
# install, if it is print a message and exit the installation

if [ "$(scratch isinstalled wlroots)" ] ;
    then
	printf " This version of labwc uses wlroots 0.17 and you have version 0.16 installed.\n Remove wlroots before install\n" 
	killall scratch
fi

