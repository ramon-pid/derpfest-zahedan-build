#!/bin/bash
set -euo pipefail

ROM_BRANCH="15.2"
DEVICE="zahedan"
MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/sajjad85gh/local_manifests.git"

echo "==> Clean old local trees"
rm -rf .repo/local_manifests
rm -rf {device,vendor,kernel}/daria
rm -rf {device,hardware}/mediatek

echo "==> Init DerpFest"
repo init -u ${MANIFEST_URL} -b ${ROM_BRANCH} --git-lfs --no-clone-bundle

echo "==> Clone local manifests"
git clone ${LOCAL_MANIFEST_URL} -b main .repo/local_manifests

echo "==> Sync source"
if [ -x /opt/crave/resync.sh ]; then
    /opt/crave/resync.sh
else
    repo sync -c --force-sync --no-clone-bundle --no-tags --optimized-fetch -j$(nproc)
fi

echo "==> Apply Soong patch"
cd build/soong
wget -O 0001-soong-HACK-disable-soong_filesystem_creator.patch \
  https://raw.githubusercontent.com/sajjad85gh/build-custom-rom/main/0001-soong-HACK-disable-soong_filesystem_creator.patch

if ! git am 0001-soong-HACK-disable-soong_filesystem_creator.patch; then
    echo "Patch already applied, skipping..."
    git am --abort >/dev/null 2>&1 || true
fi
cd -

echo "==> Export build identity"
export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave

echo "==> Build"
. build/envsetup.sh

lunch lineage_${DEVICE}-bp1a-userdebug

mka derp -j$(nproc)
