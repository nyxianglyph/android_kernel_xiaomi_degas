#!/bin/bash
# Build the GKI kernel for the Xiaomi 14T (degas) for Android.
#
# Run from the root of a Kleaf checkout of degas/manifest_15497637.xml
# (repo init -u https://android.googlesource.com/kernel/manifest -b common-android14-6.1
#  && cp common/degas/manifest_15497637.xml .repo/manifests/ && repo init -m manifest_15497637.xml
#  && repo sync), with this tree as common/.
#
#   degas/build.sh [out-dir]
#
# Produces the kernel Image, the GKI modules for system_dlkm (signed with this
# build's key, so they must ship together with this Image) and Module.symvers
# for the KMI check against the stock vendor modules.
#
# Plain make inside the Kleaf environment: the hermetic toolchain avoids host
# glibc/libbpf breakage on newer distros.
#
# The kernel release ends in the builder's name (uname -r, and Settings >
# About phone > Kernel version): 6.1.157-android14-11-g<commit>-Nyxianglyph.
# It goes after the Android release and KMI generation, which Android parses.
# RELEASE_SUFFIX= in the environment builds without it.
set -euo pipefail
root=$(pwd)
out=$(realpath -m "${1:-out/android}")
suffix=${RELEASE_SUFFIX--Nyxianglyph}
mkdir -p "$out"
env -i HOME="$HOME" USER="${USER:-build}" TERM=xterm LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c "
  set -e
  export ROOT_DIR='$root' KERNEL_DIR=common BUILD_CONFIG=common/build.config.gki.aarch64 HERMETIC_TOOLCHAIN=1
  source build/kernel/_setup_env.sh
  export KBUILD_BUILD_USER=nyxianglyph KBUILD_BUILD_HOST=degas
  cd common
  make O='$out' RELEASE_SUFFIX='$suffix' gki_defconfig
  make O='$out' RELEASE_SUFFIX='$suffix' -j\$(nproc) Image modules
  rm -rf '$out/dist'
  make O='$out' RELEASE_SUFFIX='$suffix' INSTALL_MOD_PATH='$out/dist' INSTALL_MOD_STRIP=1 modules_install
"
echo "image:   $out/arch/arm64/boot/Image"
echo "modules: $out/dist/lib/modules/"
echo "check:   python3 common/degas/kmi/crc_check.py common/degas/kmi/all_versions.txt $out/Module.symvers"
