#!/bin/sh

# Delete .checksum and .pkgfiles
rm -rf .checksums .pkgfiles

# Get the latest version and _nightly from the provided URL
url="https://ziglang.org/download/index.json"
latest_version_nightly=$(curl -s "$url" | grep -o '"version": "[^"]*' | awk -F'"' '{print $4}')
# We split the string in two by the -
latest_version=$(echo "$latest_version_nightly" | awk -F'-' '{print $1}')
latest_nightly=$(echo "$latest_version_nightly" | awk -F'-' '{print $2}')

echo "Latest version: $latest_version"
echo "Latest nightly: $latest_nightly"
# We create the latest version from the spkgbuild file
current_version=$(grep -o 'version=.*' spkgbuild | awk -F'=' '{print $2}')
current_nightly=$(grep -o '_nightly=.*' spkgbuild | awk -F'=' '{print $2}')

#We compare the current version with the latest version if they are the same we exit
if [ "$current_version" = "$latest_version" ] && [ "$current_nightly" = "$latest_nightly" ]; then
    echo "The current version is the latest version"
    exit 0
fi

# if the version is newer we make the release = 1
if [ "$current_version" != "$latest_version" ]; then
    echo "The current version is not the latest version"
    sed -i "s/release=.*/release=1/" spkgbuild
fi

# if the latest nightly is newer we get the release and add 1
if [ "$current_nightly" != "$latest_nightly" ] && [ "$current_version" = "$latest_version" ]; then
    echo "The current nightly is not the latest nightly"
    release=$(grep -o 'release=.*' spkgbuild | awk -F'=' '{print $2}')
    release=$((release + 1))
    sed -i "s/release=.*/release=$release/" spkgbuild
fi  

# Update the version and _nightly variables in spkgbuild
sed -i "s/version=.*/version=$latest_version/" spkgbuild
sed -i "s/_nightly=.*/_nightly=$latest_nightly/" spkgbuild

# Execute fakeroot pkgbuild
fakeroot pkgbuild

# We update the checksums just in case
fakeroot pkgbuild -g