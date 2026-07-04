#!/bin/bash
set -e

ROM_BRANCH="15.2"
DEVICE="zahedan"
MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/ramon-pid/zahedan-local-manifests.git"

echo "Cleaning old workspace files..."
find . -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "Initializing DerpFest source..."
repo init -u "${MANIFEST_URL}" -b "${ROM_BRANCH}" --git-lfs --no-clone-bundle

echo "Cloning local manifests..."
git clone "${LOCAL_MANIFEST_URL}" .repo/local_manifests

echo "Syncing source..."
/opt/crave/resync.sh

export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave

echo "Starting build..."
. build/envsetup.sh
lunch lineage_${DEVICE}-bp1a-user
mka derp
