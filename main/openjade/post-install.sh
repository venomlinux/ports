#!/bin/sh

/usr/bin/install-catalog --add \
	/etc/sgml/openjade-1.3.2.cat \
	/usr/share/sgml/openjade-1.3.2/catalog > /dev/null 2>&1

/usr/bin/install-catalog --add \
	/etc/sgml/openjade.cat \
	/etc/sgml/openjade-1.3.2.cat > /dev/null 2>&1
