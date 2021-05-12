#!/bin/sh

_xmlcatalog() {
	xmlcatalog --noout "$@" /etc/xml/catalog
}

version=1.79.2

[ -f /etc/xml/catalog ] || _xmlcatalog --create

for ver in $version current; do
	for x in rewriteSystem rewriteURI; do
		_xmlcatalog --add $x http://cdn.docbook.org/release/xsl/$ver \
		/usr/share/xml/docbook/xsl-stylesheets-$version

		_xmlcatalog --add $x http://docbook.sourceforge.net/release/xsl-ns/$ver \
		/usr/share/xml/docbook/xsl-stylesheets-$version

		_xmlcatalog --add $x http://docbook.sourceforge.net/release/xsl/$ver \
		/usr/share/xml/docbook/xsl-stylesheets-nons-$version
	done
done
