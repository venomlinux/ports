#!/bin/sh

getent group locate >/dev/null || groupadd locate
