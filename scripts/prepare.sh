#!/usr/bin/env bash

SOURCE_DIR=$PWD
BUILD_DIR="/tmp/pybuild"

OPENSSL_DIR="$SOURCE_DIR/openssl"
SQLCIPHER_DIR="$SOURCE_DIR/sqlcipher"
PYSQLCIPHER_DIR="$SOURCE_DIR/pysqlcipher3"

if [[ -d "$BUILD_DIR" ]]; then
  echo "$BUILD_DIR already exists, cleaning up"
  rm -rf $BUILD_DIR
fi

echo "Copying submodules to $BUILD_DIR"

cp -R "$PYSQLCIPHER_DIR" "$BUILD_DIR"
cp -R "$SQLCIPHER_DIR" "$BUILD_DIR/"
cp -R "$OPENSSL_DIR" "$BUILD_DIR/"

cp "$SOURCE_DIR/scripts/mac/build.sh" "$BUILD_DIR"

cd "$BUILD_DIR" || exit 1
echo "Applying pysqlcipher3 setup patch"
patch < "$SOURCE_DIR/patches/pysqlcipher3_macos.diff"

