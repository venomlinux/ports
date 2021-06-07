#!/bin/sh -e

dkms add -m nvidia -v 460.84
dkms build -m nvidia -v 460.84
dkms install -m nvidia -v 460.84
