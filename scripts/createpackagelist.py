#!/usr/bin/python3

import glob
import json

repo_list = ["core", "multilib", "nonfree", "testing"]
temp_json=[] 
package_name = ''
package_version = ''
for i in repo_list:
    print(i)
    for name in glob.glob('../' + i +'/*/spkgbuild'): 
        package = open(name,'r')
        Lines = package.readlines()
        for line in Lines:
            if(line.strip().startswith('name')):
                package_name = line.strip()[5:]
            if(line.strip().startswith('version')):
                package_version = line.strip()[8:]
            if(package_name != '' and package_version != ''):
                temp_json.append({"repo": i,"name": package_name,"version": package_version})
                package_name = ''
                package_version = ''

with open('packages.json', 'w') as outfile:
    json.dump(temp_json, outfile)