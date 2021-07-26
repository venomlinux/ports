#!/bin/sh

getent group scanner >/dev/null || groupadd -g 70 scanner
