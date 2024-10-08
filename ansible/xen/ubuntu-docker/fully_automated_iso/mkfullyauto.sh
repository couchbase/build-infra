#!/bin/bash -e

# Modify these as necessary

UBUNTUVER=${1-24.04.1}

# This version may not work with XenServer 7.2; not sure whether any of our hosts
# still use this. But the version that worked with 7.2 doesn't seem to work with
# XenServer 8.2, which we definitely do still use.
XEVER=8.4.0

# Derived values - probably don't modify these
UBUNTUCD=ubuntu-${UBUNTUVER}-live-server-amd64.iso
XEUTIL=xe-guest-utilities_${XEVER}_amd64.deb
AUTOISO=ubuntu-${UBUNTUVER}-fully-automated.iso

bigecho() {
  echo
  echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  echo $@
  echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  echo
}
# Check for existence of required files first
if [ ! -e ${XEUTIL} ]; then
  bigecho "Downloading ${XEUTIL}..."
  curl -L -o ${XEUTIL} --fail \
    https://github.com/xenserver/xe-guest-utilities/releases/download/v${XEVER}/xe-guest-utilities_${XEVER}-1_amd64.deb
fi
if [ ! -e ${UBUNTUCD} ]; then
  bigecho "Downloading Stock Ubuntu ${UBUNTUVER}"
  curl -LO http://releases.ubuntu.com/${UBUNTUVER}/${UBUNTUCD}
fi
bigecho "Copying to fully-automated ISO"
cp ${UBUNTUCD} ${AUTOISO}

bigecho "Updating grub, apt, etc. files on ISO"
if [ -d build ]; then
  chmod -R u+w build
  rm -rf build
fi
mkdir build
xorriso -osirrox on -dev ${AUTOISO} -extract boot/grub/grub.cfg build/grub.cfg

cd build
mkdir -p boot/grub nocloud
cp ../user-data nocloud
touch nocloud/meta-data
cp ../${XEUTIL} xe-guest-utilities.deb
cp ../docker-service.conf ../docker-daemon.json .

sed -e 's,---, autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---,g' \
  -e 's/timeout=.*/timeout=2/' \
  grub.cfg > boot/grub/grub.cfg
rm -f grub.cfg
chmod -R ugo-w .

bigecho "Adding xe-guest-utilities and cloud-init scripts"
xorriso -dev ../${AUTOISO} -boot_image any keep -pathspecs off -add *
cd ..

echo "Done!"
