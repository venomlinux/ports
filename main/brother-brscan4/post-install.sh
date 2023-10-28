#!/bin/sh

# Add brother driver to sane configuration
DLLCONF='/etc/sane.d/dll.conf'
if [ "$(grep brother4 ${DLLCONF})" = '' ]; then
   echo brother4 >> ${DLLCONF} 
fi

echo "\n
For Network Users: \n
Add network scanner entry \n
    Command : brsaneconfig4 -a name=(name your device) model=(model name) ip=xx.xx.xx.xx \n
Confirm network scanner entry \n
    Command : brsaneconfig4 -q | grep (name of your device) \n
Open a scanner application and try a test scan.\n"
