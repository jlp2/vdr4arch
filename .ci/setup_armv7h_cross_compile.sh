#!/bin/bash

set -e

# Get an ARM emulator going. This gets some support by repo-make-ci.sh later
# to get the emulator copied into the chroot environment
sudo apt-get update
sudo apt-get install qemu-user-static

# Enable a reduced repo-make.conf list. ARM build is slow so we don't build the
# full set.
rm repo-make.conf
cp repo-make-arm.conf repo-make.conf

# Install distcc
sudo apt-get install distcc

# If we don't have them cached, get "x-tools" from archlinuxarm.org
# If they update their build-chain, we have to change the checksum here!
X_TOOLS="x-tools7h"
X_TOOLS_MD5="e7f77df95a93818469a9fa562723689f"

mkdir -p "$HOME/cache"
if [ ! -s "$HOME/cache/$X_TOOLS.tar.xz" ]; then
  echo "Downloading x-tools..."
  wget -q -nc "https://archlinuxarm.org/builder/xtools/$X_TOOLS.tar.xz" -O "/var/tmp/$X_TOOLS.tar.xz"
  echo "$X_TOOLS_MD5  $X_TOOLS.tar.xz" > "/var/tmp/$X_TOOLS.tar.xz.md5"
  env -C "/var/tmp" md5sum -c "$X_TOOLS.tar.xz.md5"
  mv "/var/tmp/$X_TOOLS.tar.xz" "$HOME/cache"
fi

# Extract "x-tools"
tar -vxf "$HOME/cache/$X_TOOLS.tar.xz" -C "$HOME"

# Fill whitelist for distcc
sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-cpp
sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-cc
sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-g++
sudo ln -s /usr/bin/distcc /usr/lib/distcc/armv7l-unknown-linux-gnueabihf-c++

# Execute distcc daemon.
X_TOOLS_BIN="$HOME/$X_TOOLS/arm-unknown-linux-gnueabihf/bin"
env PATH="$X_TOOLS_BIN:/usr/bin" distccd --daemon --allow 127.0.0.1 --log-file=/var/tmp/distcc.log