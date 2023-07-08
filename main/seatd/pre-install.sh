#!/bin/sh

getent group seatd >/dev/null || groupadd -S seatd

