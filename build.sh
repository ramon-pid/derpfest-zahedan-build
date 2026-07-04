#!/bin/bash
set -e

ROM_BRANCH="15.2"
DEVICE="zahedan"
MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/ramon-pid/zahedan-local-manifests.git"

rm -rf .repo/local_manifests
rm -rf {device,vendor,kernel}/daria
rm -rf {device,hardware}/mediatek

repo init -u ${MANIFEST_URL} -b ${ROM_BRANCH} --git-lfs --no-clone-bundle

git clone ${LOCAL_MANIFEST_URL} .repo/local_manifests

/opt/crave/resync.sh

cd build/soong
wget -O 0001-soong-HACK-disable-soong_filesystem_creator.patch \
  https://raw.githubusercontent.com/sajjad85gh/build-custom-rom/main/0001-soong-HACK-disable-soong_filesystem_creator.patch

git am 0001-soong-HACK-disable-soong_filesystem_creator.patch || {
    git am --abort || true
}
cd -

export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave

. build/envsetup.sh
lunch lineage_${DEVICE}-bp1a-user
mka derp
