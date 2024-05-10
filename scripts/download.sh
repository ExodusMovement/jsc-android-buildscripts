#!/bin/bash

set -euo pipefail

# mkdircd download directory before restricting shell access
TARGET_DIR=$PWD/build/download
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}"

set -r

# NOTE: do not allow reading passed-in $SHA256SUM, just in case someone does
# something like `export SHA256SUM=true`.
if command -v sha256sum; then
  SHA256SUM=sha256sum
elif command -v gsha256sum; then
  SHA256SUM=gsha256sum
else
  echo "unable to verify downloaded contents, missing [g]sha256sum"
  exit 1
fi

git clone --branch $GIT_TAG https://github.com/WebKit/WebKit.git webkit/
# TODO: check integrity

# NOTE: ICU tarballs are made on the fly and don't produce consistent hashes.
# Verify the file tree, then verify the files.
ICU_FILE="${npm_package_config_chromiumICUCommit}.tar.gz"
ICU_URL="https://chromium.googlesource.com/chromium/deps/icu/+archive/${ICU_FILE}"
rm "$ICU_FILE" || true
wget "${ICU_URL}"
test "$(tar tf "${ICU_FILE}" | LC_ALL=C sort | "$SHA256SUM" | awk '{ print $1 }')" = "${npm_package_config_chromiumICUTreeIntegrity}"
rm -rf icu || true
mkdir icu
tar xf "${ICU_FILE}" -C icu
test "$(find icu -type f -exec "$SHA256SUM" -- {} + | LC_ALL=C sort | "$SHA256SUM" | awk '{ print $1 }')" = "${npm_package_config_chromiumICUFileIntegrity}"
