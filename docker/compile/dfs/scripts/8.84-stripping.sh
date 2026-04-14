#!/bin/bash -x

# Save debug info for a few libs, and carefully strip and replace them
# atomically to prevent crashes
debuglibs=$(find /usr -type f \( \
    -name "ld-${GLIBC_VERSION}.so" -o \
    -name "libc-*.so*" -o \
    -name "libthread_db*.so*" -o \
    -name "libquadmath*.so*" -o \
    -name "libstdc++*.so*" -o \
    -name "libitm*.so*" -o \
    -name "libatomic*.so*" \) \
)
for LIB in $debuglibs; do
    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
    libname=$(basename $LIB)
    cp $LIB /tmp/$libname
    strip --strip-unneeded /tmp/$libname
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$libname
    install -vm755 /tmp/$libname $LIB
    rm /tmp/$libname
done

# Libraries under /opt/gcc-* that we want to keep unstripped so that
# we can get debug stack traces in production (see 8.29-gcc-pass3.sh).
gcc_preserve="libstdc++ libgcc_s libgomp"

# Blindly strip everything else
for i in $(find /usr /opt -type f \! -name "*.dbg"); do
    case "$debuglibs" in
        *"$i"*)
            continue
            ;;
        *)
            # Don't strip preserved GCC runtime libraries
            skip=false
            case "$i" in /opt/gcc-*/lib/*)
                for lib in $gcc_preserve; do
                    case "$i" in */${lib}.so*) skip=true ;; esac
                done
            esac
            $skip || strip --strip-unneeded $i || true
            ;;
    esac
done
