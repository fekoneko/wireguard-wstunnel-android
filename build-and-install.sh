#!/bin/sh

BUILD_DIR='ui/build/outputs/apk/release'
WSTUNNEL_VERSION='10.5.2'
KEY_STORE_PATH="$(dirname "$(realpath "$0")")/key-store.jks" || exit 1
APKSIGNER_CMD='/opt/android-sdk/build-tools/35.0.0/apksigner'
ADB_CMD='adb'

cd "$(dirname "$0")" || exit 1

# Build for release
./gradlew assembleRelease || exit 1

cd "$BUILD_DIR" || exit 1

# There are no builds of wstunnel for these architectures on Android
zip -d ui-release-unsigned.apk 'lib/armeabi-v7a/*' 'lib/x86/*' 'lib/x86_64/*' || exit 1

# Download wstunnel and inject it into the apk because I don't know any better
url='https://github.com/erebe/wstunnel/releases/download'
url="$url/v${WSTUNNEL_VERSION}/wstunnel_${WSTUNNEL_VERSION}_linux_amd64.tar.gz"
wget "$url" || exit 1
bsdtar -xvzf "wstunnel_${WSTUNNEL_VERSION}_linux_amd64.tar.gz" wstunnel || exit 1
mkdir -p lib/arm64-v8a || exit 1
mv wstunnel lib/arm64-v8a/libwstunnel.so || exit 1
zip -u ui-release-unsigned.apk lib/arm64-v8a/* || exit 1

# Sign the APK
"$APKSIGNER_CMD" sign \
  --ks "$KEY_STORE_PATH" \
  --out ui-release-signed.apk \
  ui-release-unsigned.apk \
  || exit 1

# Install through adb
"$ADB_CMD" install ui-release-signed.apk || exit 1
