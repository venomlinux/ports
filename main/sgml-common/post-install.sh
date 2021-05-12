#!/bin/sh

install-catalog --add /etc/sgml/sgml-ent.cat \
	/usr/share/sgml/sgml-iso-entities-8879.1986/catalog >/dev/null

install-catalog --add /etc/sgml/sgml-docbook.cat \
	/etc/sgml/sgml-ent.cat >/dev/null
