#!/usr/bin/env bash
set -Eeuo pipefail

ROM_BRANCH="15.2"
DEVICE="zahedan"
MANIFEST_URL="https://github.com/DerpFest-LOS/android_manifest.git"
LOCAL_MANIFEST_URL="https://github.com/ramon-pid/zahedan-local-manifests.git"

echo "============================================================"
echo " DerpFest Zahedan Build"
echo " ROM_BRANCH=${ROM_BRANCH}"
echo " DEVICE=${DEVICE}"
echo "============================================================"

if [[ "${PWD}" != "/tmp/src/android" ]]; then
  echo "ERROR: This script must run inside Crave at /tmp/src/android"
  echo "Current PWD: ${PWD}"
  exit 1
fi

echo "Full clean workspace..."
find . -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "Repo init..."
repo init -u "${MANIFEST_URL}" -b "${ROM_BRANCH}" --git-lfs --no-clone-bundle

echo "Clone local manifests..."
git clone "${LOCAL_MANIFEST_URL}" .repo/local_manifests

echo "Repo sync..."
/opt/crave/resync.sh

echo "Sync finished."

echo "Check trees..."
test -d device/daria/zahedan-unified || {
  echo "ERROR: device/daria/zahedan-unified not found"
  find device/daria -maxdepth 4 -type f 2>/dev/null | sort | head -100 || true
  exit 1
}

test -d vendor/daria/zahedan || {
  echo "ERROR: vendor/daria/zahedan not found"
  exit 1
}

test -d kernel/daria/mt6877 || {
  echo "ERROR: kernel/daria/mt6877 not found"
  exit 1
}

echo "Kernel info:"
git -C kernel/daria/mt6877 remote -v || true
git -C kernel/daria/mt6877 branch --show-current || true
git -C kernel/daria/mt6877 log --oneline -1 || true

echo "Create compatibility path if needed..."
if [[ -d device/daria/zahedan-unified && ! -e device/daria/zahedan ]]; then
  ln -s zahedan-unified device/daria/zahedan
fi

ls -la device/daria

echo "Patch DERPFEST_BUILD_TYPE..."
for f in device/daria/zahedan-unified/lineage_zahedan.mk device/daria/zahedan/lineage_zahedan.mk; do
  if [[ -f "$f" ]]; then
    if grep -q '^DERPFEST_BUILD_TYPE[[:space:]]*:=' "$f"; then
      sed -i 's/^DERPFEST_BUILD_TYPE[[:space:]]*:=.*/DERPFEST_BUILD_TYPE := COMMUNITY/' "$f"
    else
      sed -i '1iDERPFEST_BUILD_TYPE := COMMUNITY' "$f"
    fi
    echo "Patched: $f"
    grep -n 'DERPFEST_BUILD_TYPE' "$f"
  fi
done

echo "Patch Soong..."
cd build/soong
git am --abort >/dev/null 2>&1 || true
wget -O 0001-soong-HACK-disable-soong_filesystem_creator.patch \
  https://raw.githubusercontent.com/sajjad85gh/build-custom-rom/main/0001-soong-HACK-disable-soong_filesystem_creator.patch
git am 0001-soong-HACK-disable-soong_filesystem_creator.patch
cd -

export BUILD_USERNAME=ramon
export BUILD_HOSTNAME=crave
export DERPFEST_BUILD_TYPE=COMMUNITY
export USE_CCACHE=0

echo "Build envsetup..."
. build/envsetup.sh

echo "Lunch target..."
lunch lineage_${DEVICE}-bp1a-userdebug

echo "Start build..."
m bacon
