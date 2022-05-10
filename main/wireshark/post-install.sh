#!/bin/sh

getent group wireshark >/dev/null || groupadd -g 90 wireshark


setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap
