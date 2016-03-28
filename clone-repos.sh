#!/bin/sh -ex
# Clone github repos, and pull to refresh them if they exist

! grep "NAME=\"Debian" /etc/os-release > /dev/null
NOT_DEBIAN=$?

if [ $NOT_DEBIAN = 0 ]; then
    GCC=gcc-arm-linux-gnueabihf
else
    GCC=gcc-4.7-arm-linux-gnueabihf
fi

# Only attempt to install a compiler if one isn't found
! which arm-linux-gnueabihf-gcc > /dev/null
GCC_FOUND=$?
if [ $GCC_FOUND = 0 ]; then
    sudo apt-get -y install rsync git $GCC build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools curl device-tree-compiler libncurses5-dev
else
    sudo apt-get -y install rsync git build-essential qemu kpartx binfmt-support qemu-user-static python bc parted dosfstools curl device-tree-compiler libncurses5-dev
fi

if [ ! -d u-boot ]; then
  git clone --depth 1 -b v2016.03 git://git.denx.de/u-boot.git || echo "git failed with status: $?"
else
  cd u-boot
  git pull --ff-only origin v2016.03 || echo "git failed with status: $?"
  cd ..
fi

if [ ! -d linux ]; then
  git clone --depth 1 https://github.com/torvalds/linux.git -b v4.5 || echo "git failed with status: $?"
else
  cd linux
  git reset HEAD --hard
  git pull --ff-only https://github.com/torvalds/linux.git v4.5 || echo "git failed with status: $?"
  cd ..
fi

cd linux
for i in ../patches/linux*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
done
cd ..

if [ ! -d linux-firmware ]; then
  git clone --depth 1 -b master https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git || echo "git failed with status: $?"
else
  cd linux-firmware
  git pull --ff-only https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git master || echo "git failed with status: $?"
  cd ..
fi

if [ ! -d xen ]; then
  git clone --depth 1 -b master git://xenbits.xen.org/xen.git || echo "git failed with status: $?"
else
  cd xen
  git reset HEAD --hard
  git pull --ff-only git://xenbits.xen.org/xen.git master || echo "git failed with status: $?"
  cd ..
fi

cd xen
for i in ../patches/xen*.patch; do
  if [ -e $i ]; then
    patch -p1 < $i
  fi
done
cd ..

# Clone the xen-qemu upstream now, so we can have the xen tools build clone from 
# a local repo later.
if [ ! -d qemu-xen.git ]; then
  git clone --mirror git://xenbits.xen.org/qemu-xen.git || echo "git failed with status: $?"
else
  cd qemu-xen.git
  git remote update || echo "git failed with status: $?"
  cd ..
fi
