#!/bin/sh

# The port 'python3-libxml2' conflicts with 'libxml2', now build with Python
scratch isinstalled python3-libxml2 && scratch remove -y python3-libxml2
