#!/bin/sh

getent group kvm >/dev/null || groupadd -g 61 kvm
