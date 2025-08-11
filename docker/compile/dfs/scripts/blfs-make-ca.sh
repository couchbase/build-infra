#!/bin/bash -ex

# Download and install the basics of make-ca
dfs-downloader https://github.com/lfs-book/make-ca/archive/v${MAKE_CA_VERSION}/make-ca-${MAKE_CA_VERSION}.tar.gz -m ${MAKE_CA_CHECKSUM}
tar -xf make-ca-${MAKE_CA_VERSION}.tar.gz
cd make-ca-${MAKE_CA_VERSION}

mkdir -pv /
make DESTDIR= make_ca install_bin install_cs install_mozilla_ca_root
install -vdm755 /etc/ssl/local

# Proceeed to build and install p11-kit
cd ${LFS_SRC}
dfs-downloader https://github.com/p11-glue/p11-kit/releases/download/${P11_KIT_VERSION}/p11-kit-${P11_KIT_VERSION}.tar.xz -m ${P11_KIT_CHECKSUM}
tar -xf p11-kit-${P11_KIT_VERSION}.tar.xz
cd p11-kit-${P11_KIT_VERSION}

# This edit may need to be changed in different p11-kit versions.
sed '20,$ d' -i trust/trust-extract-compat

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

mkdir p11-build &&
cd    p11-build &&

uv tool run meson setup ..  \
      --prefix=/usr         \
      --buildtype=release   \
      -D trust_paths=/etc/pki/anchors
ninja
ninja install

# "make-ca -g" expects for everything to be installed in /usr, so we
# can't run that. Extract the certdata.txt URL from make-ca, and then
# run it without the -g option.
eval $(grep 'URL=' /usr/sbin/make-ca)
# This URL is dynamic, so we can't bake in a checksum
dfs-downloader ${URL} --skip-checksum
/usr/sbin/make-ca -g
