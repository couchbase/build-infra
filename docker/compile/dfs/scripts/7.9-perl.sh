#!/bin/bash -ex

dfs-downloader https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.xz -m ${PERL_CHECKSUM}
tar -xf perl-${PERL_VERSION}.tar.xz
cd perl-${PERL_VERSION}

sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
make -j${PARALLELISM}
make install
