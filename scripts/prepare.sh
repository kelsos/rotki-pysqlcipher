#!/usr/bin/env bash

SOURCE_DIR=$PWD
BUILD_DIR="/tmp/pybuild"

SQLCIPHER_DIR="$SOURCE_DIR/sqlcipher"
PYSQLCIPHER_DIR="$SOURCE_DIR/pysqlcipher3"

if [[ -d "$BUILD_DIR" ]]; then
  echo "$BUILD_DIR already exists, cleaning up"
  rm -rf $BUILD_DIR
fi

echo "Copying submodules to $BUILD_DIR"

cp -R "$PYSQLCIPHER_DIR" "$BUILD_DIR"
cp -R "$SQLCIPHER_DIR" "$BUILD_DIR/"

BUILD_OS=$(uname -s)

if [[ $BUILD_OS == 'Linux' ]]; then
  BUILD_PLATFORM='linux'
else
  BUILD_PLATFORM='mac'
fi

echo "Copying $BUILD_PLATFORM/build.sh"

cp "$SOURCE_DIR/scripts/$BUILD_PLATFORM/build.sh" "$BUILD_DIR"

cd "$BUILD_DIR" || exit 1


echo "Preparing pysqlcipher3 setup patch"
pip install -r requirements.txt
"$SOURCE_DIR/patches/patch-gen.py" --platform "$BUILD_PLATFORM" --version "$LIB_VERSION"

patch < "$SOURCE_DIR/patches/pysqlcipher3.diff"

if [[ $BUILD_OS == 'Linux' ]]; then
  echo "Copying OpenSSL to build dir"
  cp -R "$SOURCE_DIR/openssl" "$BUILD_DIR/"
fi

if [[ -d "$SOURCE_DIR/openssl-macos-arm64" ]]; then
  echo "Copying arm64 OpenSSL"
  cp -R "$SOURCE_DIR/openssl-macos-arm64" "$BUILD_DIR/"
fi

if [[ -d "$SOURCE_DIR/openssl-macos-universal2" ]]; then
  echo "Copying universal2 OpenSSL"
  cp -R "$SOURCE_DIR/openssl-macos-universal2" "$BUILD_DIR/"
fi

if [[ -d "$SOURCE_DIR/openssl-macos-x86_64" ]]; then
  echo "Copying x86_64 OpenSSL"
  cp -R "$SOURCE_DIR/openssl-macos-x86_64" "$BUILD_DIR/"
fi
