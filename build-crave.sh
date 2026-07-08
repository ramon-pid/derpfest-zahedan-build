#!/usr/bin/env bash
set -e

ROM_BRANCH="15.2"
DEVICE="zahedan"

MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/ramon-pid/zahedan-local-manifests.git"

cd /tmp/src/android

repo init -u "$MANIFEST_URL" -b "$ROM_BRANCH" --git-lfs --no-clone-bundle

rm -rf .repo/local_manifests
git clone "$LOCAL_MANIFEST_URL" .repo/local_manifests

/opt/crave/resync.sh

rm -rf device/daria/zahedan
ln -s zahedan-unified device/daria/zahedan

ZAHD_MK="$(find device/daria -name 'lineage_zahedan.mk' | head -n1)"

sed -i '/^DERPFEST_BUILD_TYPE[[:space:]]*:=/d' "$ZAHD_MK"
sed -i '1iDERPFEST_BUILD_TYPE := COMMUNITY' "$ZAHD_MK"

cd build/soong
git am --abort >/dev/null 2>&1 || true
git reset --hard
curl -fsSL https://raw.githubusercontent.com/sajjad85gh/build-custom-rom/main/0001-soong-HACK-disable-soong_filesystem_creator.patch | git am
cd /tmp/src/android

export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave
export USE_CCACHE=0

. build/envsetup.sh
lunch lineage_${DEVICE}-bp1a-userdebug
m bacon
