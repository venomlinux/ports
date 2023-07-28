#!/bin/sh
getent group seat >/dev/null || groupadd seat
