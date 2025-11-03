FROM debian:11 AS lfs-build

# The section headers here are from "Linux From Scratch, version 12.3"
# https://www.linuxfromscratch.org/lfs/view/12.3/

# 2.2.2 Host system requirements (plus additional requirements for building in Docker)
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        binutils \
        bison \
        coreutils \
        diffutils \
        findutils \
        gawk \
        gcc \
        g++ \
        grep \
        gzip \
        m4 \
        make \
        patch \
        perl \
        python3 \
        sed \
        tar \
        texinfo \
        xz-utils \
    && apt clean all

RUN ln -sf /bin/bash /bin/sh

# Note: we store build stuff in /mnt/sources, outside the LFS tree -
# this is a change compared to the LFS book. This will be a tmpfs mount,
# and we set the WORKDIR here too, so all the individual scripts can
# assume they're already in the correct directory and it's empty. We do
# need to actually create this mount point so that we can set
# permissions on it (RUN --mount doesn't allow this), so that the
# commands we run as user `lfs` can write to it.
ARG LFS_SRC=/mnt/sources
RUN mkdir -p ${LFS_SRC} \
    && chmod 1777 ${LFS_SRC}
WORKDIR ${LFS_SRC}

# This is where we'll copy the individual scripts to. We don't just copy
# the whole `scripts` directory up front due to Docker caching -
# otherwise, changing a single script would trigger a rebuild of the
# whole Dockerfile.
ARG LFS_SCRIPTS=/lfs-scripts

# Verify host system requirements
COPY scripts/2.2.2-host-requirements.sh ${LFS_SCRIPTS}/2.2.2-host-requirements.sh
RUN ${LFS_SCRIPTS}/2.2.2-host-requirements.sh

# 2.6 Define LFS directories
ARG LFS=/mnt/lfs

# 4.2 Create limited directory layout in LFS filesystem.
COPY scripts/4.2-create-directory-layout.sh ${LFS_SCRIPTS}/4.2-create-directory-layout.sh
RUN ${LFS_SCRIPTS}/4.2-create-directory-layout.sh

# 4.3 Create the LFS user and group and set permissions
RUN set -x \
    && groupadd -g 1000 lfs \
    && useradd -s /bin/bash -g lfs -m -k /dev/null -u 1000 lfs \
    && chown -R lfs:lfs $LFS $LFS_SRC

# 4.4 Set up the environment for building LFS.
ENV LC_ALL=POSIX
# LFS_TGT is set in individual shell scripts as it needs to vary by
# architecture (and not in a way that Dockerfile's TARGETARCH can help
# with).
ENV PATH=${LFS}/pass1/bin:/bin:/usr/bin
ENV CONFIG_SITE=${LFS_SRC}/usr/share/config.site
RUN rm /etc/bash.bashrc


# Add `uv` to the PATH so we can use it for our download script. We put
# uv and the download script into `/pass1/bin` which will be on the PATH
# for the pre-chroot stages. We also copy them to `$LFS/usr/bin` which
# will be on the PATH later; we'll remove them at the very end.
COPY --from=docker.io/astral/uv:0.8.5 /uv $LFS/pass1/bin
COPY scripts/dfs-downloader $LFS/pass1/bin/dfs-downloader
RUN cp -a $LFS/pass1/bin/uv $LFS/pass1/bin/dfs-downloader $LFS/usr/bin

#
# The goal here is to create a minimal working environment - with a
# glibc version of our choosing - that we can chroot into and build gcc
# from source. This requires quite some shenanigans.
#
# PASS 1 - build a cross toolchain in this Debian environment, with
# locally-built binutils and gcc. These are installed into the nascent
# LFS image under /pass1. It would be preferable to build them entirely
# outside the LFS filesystem, but that eventually fails when trying to
# build libstdc++.
#
# Note that we don't necessarily build the same gcc here as we want in
# the final image. We need to build a gcc that we are sure will build
# our final glibc correctly. In particular, glibc 2.28 has a bug that
# causes scanf() and friends to fail when it is built with gcc 13.2.0,
# leading to nasty subtle bugs in at least the "file" command and with
# GCC LTO. So, we build an earlier version of gcc first, specified by
# the build arg INITIAL_GCC_VERSION, which will be used to build
# everything up until the final (pass 3) gcc build.
#

USER lfs

ARG PARALLELISM=8
ARG GNU_MIRROR=https://mirrors.ocf.berkeley.edu/gnu

# 5.2 Binutils - pass 1

# NOTE: picking binutils != 2.44 will require tweaking the patch in the
# later script 6.17-binutils-pass2.sh.
ARG BINUTILS_VERSION=2.44
ARG BINUTILS_CHECKSUM=49912ce774666a30806141f106124294
COPY scripts/5.2-binutils-pass1.sh ${LFS_SCRIPTS}/5.2-binutils-pass1.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/5.2-binutils-pass1.sh

# 5.3 GCC - pass 1
ARG GLIBC_VERSION=2.28
ARG INITIAL_GCC_VERSION=10.2.0
ARG INITIAL_GCC_CHECKSUM=e9fd9b1789155ad09bcf3ae747596b50
ARG MPFR_VERSION=4.2.1
ARG MPFR_CHECKSUM=523c50c6318dde6f9dc523bc0244690a
ARG GMP_VERSION=6.3.0
ARG GMP_CHECKSUM=956dc04e864001a9c22429f761f2c283
ARG MPC_VERSION=1.3.1
ARG MPC_CHECKSUM=5c9bc658c9fd0f940e8e3e0f09530c62
COPY scripts/5.3-gcc-pass1.sh ${LFS_SCRIPTS}/5.3-gcc-pass1.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/5.3-gcc-pass1.sh

#
# Build minimal libraries into /usr on the LFS filesystem: the kernel
# headers, glibc (the whole reason we're doing this dance), libstdc++,
# ncurses, and zlib. These will be rebuilt and overwritten later.
#

# 5.4 Linux API Headers
ARG LINUX_VERSION=6.13.4
ARG LINUX_CHECKSUM=13b9e6c29105a34db4647190a43d1810
COPY scripts/5.4-linux-api-headers.sh ${LFS_SCRIPTS}/5.4-linux-api-headers.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/5.4-linux-api-headers.sh

# 5.5 Glibc - this (and only this) is installed globally on the LFS filesystem.
ARG GLIBC_VERSION=2.28
ARG GLIBC_CHECKSUM=c81d2388896379997bc359d4f2084239
COPY scripts/5.5-glibc-pass1.sh ${LFS_SCRIPTS}/5.5-glibc-pass1.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/5.5-glibc-pass1.sh

# 5.6 Libstdc++ also built from INITIAL_GCC_VERSION
COPY scripts/5.6-libstdc++.sh ${LFS_SCRIPTS}/5.6-libstdc++.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/5.6-libstdc++.sh

#
# PASS 2 - Using the cross toolchain we built in pass 1, build various
# tools into /pass2 in the LFS filesystem, culminating with the second
# build of gcc. These tools will be used to build the final LFS system
# in the chroot jail.
#

# We actually don't want these pass2 tools on the PATH yet, since they
# may not be compatible with the libraries in this Debian environment.

# 6.2 M4
ARG M4_VERSION=1.4.19
ARG M4_CHECKSUM=0d90823e1426f1da2fd872df0311298d
COPY scripts/6.2-m4.sh ${LFS_SCRIPTS}/6.2-m4.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.2-m4.sh

# 6.3 Ncurses - required to build bash
ARG NCURSES_VERSION=6.5
ARG NCURSES_CHECKSUM=ac2d2629296f04c8537ca706b6977687
COPY scripts/6.3-ncurses.sh ${LFS_SCRIPTS}/6.3-ncurses.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.3-ncurses.sh

# 6.4 Bash - required to build GCC
# Use BASH_SHELL_VERSION since BASH_VERSION is a built-in variable in bash
ARG BASH_SHELL_VERSION=5.2.37
ARG BASH_SHELL_CHECKSUM=9c28f21ff65de72ca329c1779684a972
COPY scripts/6.4-bash.sh ${LFS_SCRIPTS}/6.4-bash.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.4-bash.sh

# 6.5 Coreutils
ARG COREUTILS_VERSION=9.6
ARG COREUTILS_CHECKSUM=0ed6cc983fe02973bc98803155cc1733
COPY scripts/6.5-coreutils.sh ${LFS_SCRIPTS}/6.5-coreutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.5-coreutils.sh

# 6.6 Diffutils
ARG DIFFUTILS_VERSION=3.9
ARG DIFFUTILS_CHECKSUM=cf0a65266058bf22fe3feb69e57ffc5b
COPY scripts/6.6-diffutils.sh ${LFS_SCRIPTS}/6.6-diffutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.6-diffutils.sh

# 6.7 File
ARG FILE_VERSION=5.46
ARG FILE_CHECKSUM=459da2d4b534801e2e2861611d823864
COPY scripts/6.7-file.sh ${LFS_SCRIPTS}/6.7-file.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.7-file.sh

# 6.8 Findutils
ARG FINDUTILS_VERSION=4.10.0
ARG FINDUTILS_CHECKSUM=870cfd71c07d37ebe56f9f4aaf4ad872
COPY scripts/6.8-findutils.sh ${LFS_SCRIPTS}/6.8-findutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.8-findutils.sh

# 6.9 Gawk
ARG GAWK_VERSION=5.3.1
ARG GAWK_CHECKSUM=4e9292a06b43694500e0620851762eec
COPY scripts/6.9-gawk.sh ${LFS_SCRIPTS}/6.9-gawk.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.9-gawk.sh

# 6.10 Grep
ARG GREP_VERSION=3.11
ARG GREP_CHECKSUM=7c9bbd74492131245f7cdb291fa142c0
COPY scripts/6.10-grep.sh ${LFS_SCRIPTS}/6.10-grep.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.10-grep.sh

# 6.11 Gzip
ARG GZIP_VERSION=1.13
ARG GZIP_CHECKSUM=d5c9fc9441288817a4a0be2da0249e29
COPY scripts/6.11-gzip.sh ${LFS_SCRIPTS}/6.11-gzip.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.11-gzip.sh

# 6.12 Make - note that earlier versions of glibc send make 4.4+ into an
# infinite loop, so for this pass build make 4.3. We'll build a newer
# one in pass 3.
# https://github.com/crosstool-ng/crosstool-ng/issues/1932#issuecomment-1528139734
ARG PASS2_MAKE_VERSION=4.3
ARG PASS2_MAKE_CHECKSUM=fc7a67ea86ace13195b0bce683fd4469
COPY scripts/6.12-make.sh ${LFS_SCRIPTS}/6.12-make.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.12-make.sh

# 6.13 Patch
ARG PATCH_VERSION=2.7.6
ARG PATCH_CHECKSUM=4c68cee989d83c87b00a3860bcd05600
COPY scripts/6.13-patch.sh ${LFS_SCRIPTS}/6.13-patch.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.13-patch.sh

# 6.14 Sed
ARG SED_VERSION=4.9
ARG SED_CHECKSUM=6aac9b2dbafcd5b7a67a8a9bcb8036c3
COPY scripts/6.14-sed.sh ${LFS_SCRIPTS}/6.14-sed.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.14-sed.sh

# 6.15 Tar
ARG TAR_VERSION=1.35
ARG TAR_CHECKSUM=a2d8042658cfd8ea939e6d911eaf4152
COPY scripts/6.15-tar.sh ${LFS_SCRIPTS}/6.15-tar.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.15-tar.sh

# 6.16 XZ
ARG XZ_VERSION=5.6.4
ARG XZ_CHECKSUM=4b1cf07d45ec7eb90a01dd3c00311a3e
COPY scripts/6.16-xz.sh ${LFS_SCRIPTS}/6.16-xz.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.16-xz.sh

# 6.17 Binutils - pass 2
COPY scripts/6.17-binutils-pass2.sh ${LFS_SCRIPTS}/6.17-binutils-pass2.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.17-binutils-pass2.sh

# 6.18 GCC - pass 2 (still building INITIAL_GCC_VERSION)
COPY scripts/6.18-gcc-pass2.sh ${LFS_SCRIPTS}/6.18-gcc-pass2.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/6.18-gcc-pass2.sh

# 7.2 Clean up LFS - chown everything back to root, and delete /pass1.
# Also create /tmp.
USER root
RUN set -x \
    && mkdir -p ${LFS}/tmp \
    && chmod 1777 ${LFS}/tmp \
    && rm -rf ${LFS}/pass1 \
    && chown -R root:root ${LFS}

FROM scratch AS lfs-chroot

#
# PASS 3 - "chroot" by restarting the build from the current LFS image,
# and rebuild everything into /usr.
#

COPY --from=lfs-build /mnt/lfs /
ARG LFS_SCRIPTS=/lfs-scripts

# Need to re-create this directory in the new "chroot" environment.
# Everything is running as `root` from now on, so no need to pre-create
# the directory; Docker will mount it with permissions writable by root.
ARG LFS_SRC=/mnt/sources
WORKDIR ${LFS_SRC}

# Now we want the /pass2 tools on the PATH, but put them last so that
# we'll prefer to use the ones we're about to re-build into /usr. Also
# add /usr/sbin since several of these tools install there.
ENV PATH=/bin:/usr/bin:/usr/sbin:/pass2/bin
ENV HOME=/root
ARG PARALLELISM=8
ARG GNU_MIRROR=https://mirrors.ocf.berkeley.edu/gnu

# 7.6 Create essential files
COPY scripts/7.6-essential-files.sh ${LFS_SCRIPTS}/7.6-essential-files.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/7.6-essential-files.sh

# 7.7 gettext
ARG GETTEXT_VERSION=0.24
ARG GETTEXT_CHECKSUM=87aea3013802a3c60fa3feb5c7164069
COPY scripts/7.7-gettext.sh ${LFS_SCRIPTS}/7.7-gettext.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/7.7-gettext.sh

# 7.8 Bison
ARG BISON_VERSION=3.8.2
ARG BISON_CHECKSUM=c28f119f405a2304ff0a7ccdcc629713
COPY scripts/7.8-bison.sh ${LFS_SCRIPTS}/7.8-bison.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/7.8-bison.sh

# 7.9 Perl
ARG PERL_VERSION=5.40.1
ARG PERL_CHECKSUM=bab3547a5cdf2302ee0396419d74a42e
COPY scripts/7.9-perl.sh ${LFS_SCRIPTS}/7.9-perl.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/7.9-perl.sh

# 8.5.1 install glibc - pass 3
ARG GLIBC_VERSION=2.28
ARG GLIBC_CHECKSUM=c81d2388896379997bc359d4f2084239
ARG TZDATA_VERSION=2025a
ARG TZDATA_CHECKSUM=404229390c06b7440f5e48d12c1a3251
COPY scripts/8.5-glibc-pass3.sh ${LFS_SCRIPTS}/8.5-glibc-pass3.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.5-glibc-pass3.sh

# 8.6 zlib
ARG ZLIB_VERSION=1.3.1
ARG ZLIB_CHECKSUM=5e6af153311327e516690d300527ec9e
COPY scripts/8.6-zlib.sh ${LFS_SCRIPTS}/8.6-zlib.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.6-zlib.sh

# 8.7 bzip2
ARG BZIP2_VERSION=1.0.8
ARG BZIP2_CHECKSUM=67e051268d0c475ea773822f7500d0e5
COPY scripts/8.7-bzip2.sh ${LFS_SCRIPTS}/8.7-bzip2.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.7-bzip2.sh

# 8.8 XZ
ARG XZ_VERSION=5.6.4
ARG XZ_CHECKSUM=4b1cf07d45ec7eb90a01dd3c00311a3e
COPY scripts/8.8-xz.sh ${LFS_SCRIPTS}/8.8-xz.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.8-xz.sh

# 8.9 LZ4
ARG LZ4_VERSION=1.10.0
ARG LZ4_CHECKSUM=dead9f5f1966d9ae56e1e32761e4e675
COPY scripts/8.9-lz4.sh ${LFS_SCRIPTS}/8.9-lz4.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.9-lz4.sh

# 8.10 zstd
ARG ZSTD_VERSION=1.5.7
ARG ZSTD_CHECKSUM=780fc1896922b1bc52a4e90980cdda48
COPY scripts/8.10-zstd.sh ${LFS_SCRIPTS}/8.10-zstd.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.10-zstd.sh

# 8.11 File
ARG FILE_VERSION=5.46
ARG FILE_CHECKSUM=459da2d4b534801e2e2861611d823864
COPY scripts/8.11-file.sh ${LFS_SCRIPTS}/8.11-file.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.11-file.sh

# 8.12 readline
ARG READLINE_VERSION=8.2.13
ARG READLINE_CHECKSUM=05080bf3801e6874bb115cd6700b708f
COPY scripts/8.12-readline.sh ${LFS_SCRIPTS}/8.12-readline.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.12-readline.sh

# 8.13 M4
ARG M4_VERSION=1.4.19
ARG M4_CHECKSUM=0d90823e1426f1da2fd872df0311298d
COPY scripts/8.13-m4.sh ${LFS_SCRIPTS}/8.13-m4.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.13-m4.sh

# 8.15 flex
ARG FLEX_VERSION=2.6.4
ARG FLEX_CHECKSUM=2882e3179748cc9f9c23ec593d6adc8d
COPY scripts/8.15-flex.sh ${LFS_SCRIPTS}/8.15-flex.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.15-flex.sh

# 8.19 pkgconf
ARG PKGCONF_VERSION=2.3.0
ARG PKGCONF_CHECKSUM=833363e77b5bed0131c7bc4cc6f7747b
COPY scripts/8.19-pkgconf.sh ${LFS_SCRIPTS}/8.19-pkgconf.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.19-pkgconf.sh

# 8.20 Binutils - pass 3. This is installing the "binutils-with-gold"
# package as that is still needed on aarch64.
ARG BINUTILS_WITH_GOLD_VERSION=2.44
ARG BINUTILS_WITH_GOLD_CHECKSUM=255db231c9f9d556ae597b8ec8cc5740
COPY scripts/8.20-binutils-pass3.sh ${LFS_SCRIPTS}/8.20-binutils-pass3.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.20-binutils-pass3.sh

# 8.21 GMP
ARG GMP_VERSION=6.3.0
ARG GMP_CHECKSUM=956dc04e864001a9c22429f761f2c283
COPY scripts/8.21-gmp.sh ${LFS_SCRIPTS}/8.21-gmp.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.21-gmp.sh

# 8.22 MPFR
ARG MPFR_VERSION=4.2.1
ARG MPFR_CHECKSUM=523c50c6318dde6f9dc523bc0244690a
COPY scripts/8.22-mpfr.sh ${LFS_SCRIPTS}/8.22-mpfr.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.22-mpfr.sh

# 8.23 MPC
ARG MPC_VERSION=1.3.1
ARG MPC_CHECKSUM=5c9bc658c9fd0f940e8e3e0f09530c62
COPY scripts/8.23-mpc.sh ${LFS_SCRIPTS}/8.23-mpc.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.23-mpc.sh

# 8.24 Attributes
ARG ATTR_VERSION=2.5.2
ARG ATTR_CHECKSUM=227043ec2f6ca03c0948df5517f9c927
COPY scripts/8.24-attr.sh ${LFS_SCRIPTS}/8.24-attr.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.24-attr.sh

# 8.27 libxcrypt
ARG LIBXCRYPT_VERSION=4.4.38
ARG LIBXCRYPT_CHECKSUM=1796a5d20098e9dd9e3f576803c83000
COPY scripts/8.27-libxcrypt.sh ${LFS_SCRIPTS}/8.27-libxcrypt.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.27-libxcrypt.sh

# 8.28 shadow
ARG SHADOW_VERSION=4.17.3
ARG SHADOW_CHECKSUM=0da190e53ecee76237e4c8f3f39531ed
COPY scripts/8.28-shadow.sh ${LFS_SCRIPTS}/8.28-shadow.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.28-shadow.sh

# 8.29 GCC - pass 3
ARG GCC_VERSION=13.2.0
ARG GCC_CHECKSUM=e0e48554cc6e4f261d55ddee9ab69075
COPY scripts/8.29-gcc-pass3.sh ${LFS_SCRIPTS}/8.29-gcc-pass3.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.29-gcc-pass3.sh

# 8.30 Ncurses
ARG NCURSES_VERSION=6.5
ARG NCURSES_CHECKSUM=ac2d2629296f04c8537ca706b6977687
COPY scripts/8.30-ncurses.sh ${LFS_SCRIPTS}/8.30-ncurses.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.30-ncurses.sh

# 8.31 sed
ARG SED_VERSION=4.9
ARG SED_CHECKSUM=a50000a406f767bfa35db319704ef7b5
COPY scripts/8.31-sed.sh ${LFS_SCRIPTS}/8.31-sed.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.31-sed.sh

# 8.32 psmisc
ARG PSMISC_VERSION=23.7
ARG PSMISC_CHECKSUM=53eae841735189a896d614cba440eb10
COPY scripts/8.32-psmisc.sh ${LFS_SCRIPTS}/8.32-psmisc.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.32-psmisc.sh

# 8.35 grep
ARG GREP_VERSION=3.11
ARG GREP_CHECKSUM=74fc74cf0593de11b7762b53dec191d4
COPY scripts/8.35-grep.sh ${LFS_SCRIPTS}/8.35-grep.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.35-grep.sh

# 8.36 Bash
# Use BASH_SHELL_VERSION since BASH_VERSION is a built-in variable in bash
ARG BASH_SHELL_VERSION=5.2.37
ARG BASH_SHELL_CHECKSUM=9c28f21ff65de72ca329c1779684a972
COPY scripts/8.36-bash.sh ${LFS_SCRIPTS}/8.36-bash.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.36-bash.sh

# Now we can fix up this shell script from glibc to use the new bash
RUN sed -i -e 's/pass2/usr/' /usr/bin/ldd

# 8.37 libtool
ARG LIBTOOL_VERSION=2.5.4
ARG LIBTOOL_CHECKSUM=862d906983d9b423b072285d999d8672
COPY scripts/8.37-libtool.sh ${LFS_SCRIPTS}/8.37-libtool.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.37-libtool.sh

# 8.42 Less
ARG LESS_VERSION=668
ARG LESS_CHECKSUM=d72760386c5f80702890340d2f66c302
COPY scripts/8.42-less.sh ${LFS_SCRIPTS}/8.42-less.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.42-less.sh

# 8.46 Autoconf
ARG AUTOCONF_VERSION=2.72
ARG AUTOCONF_CHECKSUM=bac878ad1e88ca3fcf7c570910cf9af1
COPY scripts/8.46-autoconf.sh ${LFS_SCRIPTS}/8.46-autoconf.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.46-autoconf.sh

# 8.47 Automake
ARG AUTOMAKE_VERSION=1.17
ARG AUTOMAKE_CHECKSUM=f908133b080073f3907389f0f73d76f4
COPY scripts/8.47-automake.sh ${LFS_SCRIPTS}/8.47-automake.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.47-automake.sh

# 8.48 OpenSSL
ARG OPENSSL_VERSION=3.4.1
ARG OPENSSL_CHECKSUM=fb7a747ac6793a7ad7118eaba45db379
COPY scripts/8.48-openssl.sh ${LFS_SCRIPTS}/8.48-openssl.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.48-openssl.sh

# 8.49 Libelf
ARG LIBELF_VERSION=0.192
ARG LIBELF_CHECKSUM=a6bb1efc147302cfc15b5c2b827f186a
COPY scripts/8.49-libelf.sh ${LFS_SCRIPTS}/8.49-libelf.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.49-libelf.sh

# 8.50 libffi
ARG LIBFFI_VERSION=3.4.7
ARG LIBFFI_CHECKSUM=696a1d483a1174ce8a477575546a5284
COPY scripts/8.50-libffi.sh ${LFS_SCRIPTS}/8.50-libffi.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.50-libffi.sh

# 8.55 - note that we install Ninja later in the BLFS section.

# 8.58 coreutils
ARG COREUTILS_VERSION=9.6
ARG COREUTILS_CHECKSUM=0ed6cc983fe02973bc98803155cc1733
COPY scripts/8.58-coreutils.sh ${LFS_SCRIPTS}/8.58-coreutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.58-coreutils.sh

# 8.60 diffutils
ARG DIFFUTILS_VERSION=3.11
ARG DIFFUTILS_CHECKSUM=c47d5598072391ac5ae7f5e3163e1d54
COPY scripts/8.60-diffutils.sh ${LFS_SCRIPTS}/8.60-diffutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.60-diffutils.sh

# 8.61 gawk
ARG GAWK_VERSION=5.3.1
ARG GAWK_CHECKSUM=4e9292a06b43694500e0620851762eec
COPY scripts/8.61-gawk.sh ${LFS_SCRIPTS}/8.61-gawk.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.61-gawk.sh

# 8.62 findutils
ARG FINDUTILS_VERSION=4.10.0
ARG FINDUTILS_CHECKSUM=870cfd71c07d37ebe56f9f4aaf4ad872
COPY scripts/8.62-findutils.sh ${LFS_SCRIPTS}/8.62-findutils.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.62-findutils.sh

# 8.65 gzip
ARG GZIP_VERSION=1.13
ARG GZIP_CHECKSUM=d5c9fc9441288817a4a0be2da0249e29
COPY scripts/8.65-gzip.sh ${LFS_SCRIPTS}/8.65-gzip.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.65-gzip.sh

# 8.69 make
# Now we build make 4.4.1, rather than the earlier version we needed due
# to glibc.
ARG MAKE_VERSION=4.4.1
ARG MAKE_CHECKSUM=c8469a3713cbbe04d955d4ae4be23eeb
COPY scripts/8.69-make.sh ${LFS_SCRIPTS}/8.69-make.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.69-make.sh

# 8.70 patch
ARG PATCH_VERSION=2.7.6
ARG PATCH_CHECKSUM=4c68cee989d83c87b00a3860bcd05600
COPY scripts/8.70-patch.sh ${LFS_SCRIPTS}/8.70-patch.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.70-patch.sh

# 8.71 tar
ARG TAR_VERSION=1.35
ARG TAR_CHECKSUM=a2d8042658cfd8ea939e6d911eaf4152
COPY scripts/8.71-tar.sh ${LFS_SCRIPTS}/8.71-tar.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.71-tar.sh

# 8.78 procps-ng
ARG PROCPS_VERSION=4.0.5
ARG PROCPS_CHECKSUM=90803e64f51f192f3325d25c3335d057
COPY scripts/8.78-procps.sh ${LFS_SCRIPTS}/8.78-procps.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.78-procps.sh

# 8.79 util-linux
ARG UTIL_LINUX_VERSION=2.40.4
ARG UTIL_LINUX_CHECKSUM=f9cbb1c8315d8ccbeb0ec36d10350304
COPY scripts/8.79-util-linux.sh ${LFS_SCRIPTS}/8.79-util-linux.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.79-util-linux.sh

# Various cleanups and fixups - this eliminates /pass2
COPY scripts/8.xx-cleanup.sh ${LFS_SCRIPTS}/8.xx-cleanup.sh
RUN ${LFS_SCRIPTS}/8.xx-cleanup.sh

# 8.84 Strip everything
COPY scripts/8.84-stripping.sh ${LFS_SCRIPTS}/8.84-stripping.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.84-stripping.sh

RUN rm -rf ${LFS_SCRIPTS}

FROM scratch AS blfs-stage1

#
# PASS 4: Build BLFS packages.
#

COPY --from=lfs-chroot / /
ENV PATH=/opt/gcc-13.2.0/bin:/usr/bin:/usr/sbin
ARG GNU_MIRROR=https://mirrors.ocf.berkeley.edu/gnu
ARG PARALLELISM=8
ARG LFS_SCRIPTS=/lfs-scripts
ARG LFS_SRC=/mnt/sources
WORKDIR ${LFS_SRC}

# All we *really* want here is curl and git. However, curl requires
# libpsl, and libpsl in turn requires libidn2 and libunistring. So start
# by installing those.

# libunistring
ARG LIBUNISTRING_VERSION=1.3
ARG LIBUNISTRING_CHECKSUM=57dfd9e4eba93913a564aa14eab8052e
COPY scripts/blfs-libunistring.sh ${LFS_SCRIPTS}/blfs-libunistring.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-libunistring.sh

# libidn2
ARG LIBIDN2_VERSION=2.3.8
ARG LIBIDN2_CHECKSUM=a8e113e040d57a523684e141970eea7a
COPY scripts/blfs-libidn2.sh ${LFS_SCRIPTS}/blfs-libidn2.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-libidn2.sh

# libpsl requires ninja to build. We're OK with this in the final image,
# although we install it from a binary download which in turn requires
# 7zip. Guess it's fine to have that in the final image too.

# 7zip (from binary package)
ARG SEVENZIP_VERSION=25.00
ARG SEVENZIP_X86_64_CHECKSUM=e4e1a995b8e668eec1fec27e2fda5b52
ARG SEVENZIP_AARCH64_CHECKSUM=273f53733352e654a5d55479292c3d35
COPY scripts/blfs-7zip.sh ${LFS_SCRIPTS}/blfs-7zip.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-7zip.sh

# ninja (from binary package)
ARG NINJA_VERSION=1.13.1
ARG NINJA_X86_64_CHECKSUM=a93b5df978dfd36464151d92281febc5
ARG NINJA_AARCH64_CHECKSUM=94bccf50d7855433df8dc744d863046a
COPY scripts/blfs-ninja.sh ${LFS_SCRIPTS}/blfs-ninja.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-ninja.sh

# libpsl
ARG LIBPSL_VERSION=0.21.5
ARG LIBPSL_CHECKSUM=870a798ee9860b6e77896548428dba7b
COPY scripts/blfs-libpsl.sh ${LFS_SCRIPTS}/blfs-libpsl.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-libpsl.sh

# Also, before we build curl, we need to install the CA certificates.
# LFS offers a useful tool to do the complex machinations for this,
# called make-ca. However, we don't need this tool in the final image.
# Also, make-ca requires p11-kit, which we'd prefer not to install in
# the final image. Unfortunately, make-ca really can't do its job
# without being installed globally. So, we're about to take a little
# side trip where we install p11-kit and make-ca into a temporary image,
# and then jump back to this image and just copy /etc/pki and /etc/ssl
# from the temporary image.

# First, though, p11-kit requires libtasn1, which we may as well have in
# the final image.
ARG LIBTASN1_VERSION=4.20.0
ARG LIBTASN1_CHECKSUM=930f71d788cf37505a0327c1b84741be
COPY scripts/blfs-libtasn1.sh ${LFS_SCRIPTS}/blfs-libtasn1.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-libtasn1.sh

FROM blfs-stage1 AS blfs-make-ca

# Build this in a separate stage because it kind of dumps stuff
# everywhere that we don't want in the final image. We'll copy the
# actual cert stuff out in the next stage.

# make-ca, which also builds p11-kit
ARG MAKE_CA_VERSION=1.16.1
ARG MAKE_CA_CHECKSUM=bf9cea2d24fc5344d4951b49f275c595
ARG P11_KIT_VERSION=0.25.5
ARG P11_KIT_CHECKSUM=e9c5675508fcd8be54aa4c8cb8e794fc
COPY scripts/blfs-make-ca.sh ${LFS_SCRIPTS}/blfs-make-ca.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-make-ca.sh

FROM blfs-stage1 AS blfs-stage2

# Now we can copy the CA certificates from the temporary image.
COPY --from=blfs-make-ca /etc/pki /etc/pki
COPY --from=blfs-make-ca /etc/ssl /etc/ssl

# At long last: curl!
ARG CURL_VERSION=8.15.0
ARG CURL_CHECKSUM=b8872bb6cc5d18d03bea8ff5090b2b81
COPY scripts/blfs-curl.sh ${LFS_SCRIPTS}/blfs-curl.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-curl.sh

# Sudo
ARG SUDO_VERSION=1.9.17p1
ARG SUDO_CHECKSUM=231106344ffe541fa8e0bd4caf322497
COPY scripts/blfs-sudo.sh ${LFS_SCRIPTS}/blfs-sudo.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-sudo.sh

# OpenSSH
ARG OPENSSH_VERSION=10.0p1
ARG OPENSSH_CHECKSUM=689148621a2eaa734497b12bed1c5202
COPY scripts/blfs-openssh.sh ${LFS_SCRIPTS}/blfs-openssh.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-openssh.sh

# Fake "which" from BLFS
COPY scripts/which /usr/bin/which

# chrpath
ARG CHRPATH_VERSION=0.18
ARG CHRPATH_CHECKSUM=3220be4f47361bfd0b76e2132c0219c0
COPY scripts/blfs-chrpath.sh ${LFS_SCRIPTS}/blfs-chrpath.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-chrpath.sh

# Final strip. Re-use the script from step 8.84. Note: we do this before
# compiling git, because git makes heavy use of hard-linked files -
# stripping them after installation will break the hard links, consuming
# far more disk space.
COPY scripts/8.84-stripping.sh ${LFS_SCRIPTS}/8.84-stripping.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/8.84-stripping.sh

# And finally, git.
ARG GIT_VERSION=2.50.1
ARG GIT_CHECKSUM=2cb96fae126d66f8ff23a68f8dd5d748
COPY scripts/blfs-git.sh ${LFS_SCRIPTS}/blfs-git.sh
RUN --mount=type=tmpfs,target=${LFS_SRC} \
    ${LFS_SCRIPTS}/blfs-git.sh

# Final cleanup!
COPY scripts/blfs-cleanup.sh ${LFS_SCRIPTS}/blfs-cleanup.sh
RUN ${LFS_SCRIPTS}/blfs-cleanup.sh

# Flatten the final image.

FROM scratch AS docker-from-scratch
COPY --from=blfs-stage2 / /

RUN mkdir -pv /usr/local/bin
ENV PATH=/opt/gcc-13.2.0/bin:/usr/bin:/usr/local/bin:/usr/sbin
ENV LANG=en_US.UTF-8
ENV PS1="[\[\e[1$(if [ \"`id -u`\" = \"0\" ]; then echo -e ';31'; else echo -e ';34'; fi)m\]\u\[\e[1;36m\]\[\033[m\]@\[\e[1;36m\]\h\[\033[m\]:\[\e[0m\]\[\e[1;32m\]\W\[\e[0m\]]$ "
CMD ["bash"]
