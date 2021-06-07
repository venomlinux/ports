#!/bin/sh -e

dkms add -m vboxhost -v 6.1.22
dkms build -m vboxhost -v 6.1.22
dkms install -m vboxhost -v 6.1.22
