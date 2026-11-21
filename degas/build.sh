#!/bin/bash
# Build the Halium GKI kernel for the Xiaomi 14T (degas).
#
# Run from the root of a Kleaf checkout of degas/manifest_15497637.xml
# (repo init -u https://android.googlesource.com/kernel/manifest -b common-android14-6.1
#  && cp common/degas/manifest_15497637.xml .repo/manifests/ && repo init -m manifest_15497637.xml
#  && repo sync), with this tree as common/.
#
#   degas/build.sh [ut|androidtest] [out-dir]
#
#   ut           halium.config as is (AppArmor first) - Ubuntu Touch / Sailfish
#   androidtest  + degas_androidtest.config (SELinux first) - boots HyperOS/TWRP
#
# Plain make inside the Kleaf environment: the hermetic toolchain avoids host
# glibc/libbpf breakage on newer distros.
set -euo pipefail
flavor=${1:-ut}
root=$(pwd)
out=$(realpath -m "${2:-out/halium-$flavor}")
frags="gki_defconfig halium.config"
[ "$flavor" = androidtest ] && frags="$frags degas_androidtest.config"
mkdir -p "$out"
env -i HOME="$HOME" USER="${USER:-build}" TERM=xterm LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c "
  set -e
  export ROOT_DIR='$root' KERNEL_DIR=common BUILD_CONFIG=common/build.config.gki.aarch64 HERMETIC_TOOLCHAIN=1
  source build/kernel/_setup_env.sh
  cd common
  make O='$out' $frags
  make O='$out' -j\$(nproc) Image modules
"
echo "built: $out/arch/arm64/boot/Image"
echo "check: python3 common/degas/kmi/crc_check.py common/degas/kmi/all_versions.txt $out/Module.symvers"
