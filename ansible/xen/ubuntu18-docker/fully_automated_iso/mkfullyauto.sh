#!/bin/bash -e

VERSION=${1-18.04}
UBUNTUCD=ubuntu-${VERSION}-server-amd64.iso
XEUTIL=xe-guest-utilities_7.4.0-1_amd64.deb
AUTOISO=ubuntu-${VERSION}-fully-automated.iso

bigecho() {
  echo
  echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  echo $@
  echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  echo
}
# Check for existence of required files first
if [ ! -e ${XEUTIL} ]; then
  echo "xe-guest-utilities not found - please extract from guest-tools.iso"
  exit 1
fi
if [ ! -e ${UBUNTUCD} ]; then
  bigecho "Downloading Stock Ubuntu ${VERSION}"
  curl -LO http://releases.ubuntu.com/${VERSION}/${UBUNTUCD}
fi

bigecho "Extracting Ubuntu ${VERSION} to 'iso' subdir"
sudo rm -rf iso tmpmount
sudo mkdir tmpmount
sudo mount ${UBUNTUCD} $(pwd)/tmpmount
sudo cp -pRf tmpmount iso
sudo umount $(pwd)/tmpmount

bigecho "Adding xe-guest-utilities and Kickstart script"
sudo cp ${XEUTIL} ks.cfg iso
sudo cp isolinux.cfg iso/isolinux

bigecho "Re-packaging new ISO"
cd iso
sudo mkisofs -o ../${AUTOISO} \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -J -R -V "Ubuntu ${VERSION} Fully Automated" .
cd ..
sudo chmod 644 ${AUTOISO}

bigecho "Cleaning up"
sudo rm -rf iso tmpmount

echo "Done!"
