#!/bin/bash -e

mkdir -pv $LFS/{etc,var,pass1,pass2} $LFS/usr/{bin,lib,sbin}
mkdir -pv $LFS/{pass1,pass2}/bin

for i in bin lib sbin; do
    ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
    x86_64)
        mkdir -pv $LFS/lib64
        ;;
esac
