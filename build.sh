#!/bin/bash
set -e

ROM_BRANCH="15.2"
DEVICE="zahedan"
MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/ramon-pid/zahedan-local-manifests.git"

rm -rf .repo/local_manifests
rm -rf device/daria
rm -rf vendor/daria
rm -rf kernel/daria
rm -rf device/mediatek
rm -rf hardware/mediatek

repo init -u "${MANIFEST_URL}" -b "${ROM_BRANCH}" --git-lfs --no-clone-bundle

git clone "${LOCAL_MANIFEST_URL}" .repo/local_manifests

/opt/crave/resync.sh

cd build/soong
wget -O 0001-soong-HACK-disable-soong_filesystem_creator.patch \
  https://raw.githubusercontent.com/sajjad85gh/build-custom-rom/main/0001-soong-HACK-disable-soong_filesystem_creator.patch
git am 0001-soong-HACK-disable-soong_filesystem_creator.patch || true
cd -


# Fix DerpFest recursive build type issue
ZAHD_MK="$(find device/daria -path '*/lineage_zahedan.mk' | head -n1)"
if [ -z "$ZAHD_MK" ]; then
  echo "ERROR: lineage_zahedan.mk not found under device/daria"
  find device/daria -maxdepth 4 -type f | sort || true
  exit 1
fi

echo "Using product makefile: $ZAHD_MK"
grep -q '^DERPFEST_BUILD_TYPE[[:space:]]*:=' "$ZAHD_MK" || \
  sed -i '1iDERPFEST_BUILD_TYPE := COMMUNITY' "$ZAHD_MK"

grep -n 'DERPFEST_BUILD_TYPE' "$ZAHD_MK"

export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave

. build/envsetup.sh
lunch lineage_${DEVICE}-bp1a-userdebug

m bacon
