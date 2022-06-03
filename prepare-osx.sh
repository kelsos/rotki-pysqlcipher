#!/usr/bin/env bash

WORKDIR=$PWD
BUILDDIR=/tmp/pybuild
SQLCIPHER_DIR="$BUILDDIR/sqlcipher"
PYSQLCIPHER_DIR="$BUILDDIR/pysqlcipher3"

if [[ -d "$BUILDDIR" ]]; then
    echo "Warning $BUILDDIR exists"
    exit 1
else
    mkdir "$BUILDDIR"
fi

#cp -R "$WORKDIR/openssl" "$BUILDDIR/openssl_intel"
#cp -R "$WORKDIR/openssl" "$BUILDDIR/openssl_arm64"
#
#export MACOSX_DEPLOYMENT_TARGET=10.9
#cd "$BUILDDIR/openssl_intel" || exit 1
#./Configure darwin64-x86_64-cc shared
#make
#
#export MACOSX_DEPLOYMENT_TARGET=10.15 #/* arm64 only with Big Sur -> minimum might be 10.16 or 11.0 */)
#cd "$BUILDDIR/openssl_arm64" || exit 1
#./Configure enable-rc5 zlib darwin64-arm64-cc no-asm > /dev/null
#make > /dev/null
#
#mkdir "$BUILDDIR/openssl_universal"
#lipo -create "$BUILDDIR/openssl_arm64/libcrypto.a" "$BUILDDIR/openssl_intel/libcrypto.a" -output "$BUILDDIR/openssl_universal/libcrypto.a"
#lipo -create "$BUILDDIR/openssl_arm64/libssl.a" "$BUILDDIR/openssl_intel/libssl.a" -output "$BUILDDIR/openssl_universal/libssl.a"

# Go into the directory and build sqlcipher
echo "Creating sqlcipher amalgamation";
mkdir -p "$SQLCIPHER_DIR"
cp -R "$WORKDIR/sqlcipher" "$BUILDDIR"
cd "$SQLCIPHER_DIR" || exit 1

export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix)/lib"

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -I$(brew --prefix)/include" \

make sqlite3.c > /dev/null

cd "$WORKDIR" || exit 1
cp -R pysqlcipher3 "$BUILDDIR"
cd "$PYSQLCIPHER_DIR" || exit 1
echo "Applying pysqlcipher3 setup patch"
patch < "$WORKDIR/patches/pysqlcipher3_linux.diff"

if [[ ! -d "$PYSQLCIPHER_DIR/amalgamation" ]]; then
    mkdir "$PYSQLCIPHER_DIR/amalgamation"
fi

cp "$BUILDDIR/sqlcipher/sqlite3.c" $BUILDDIR/pysqlcipher3/amalgamation
cp "$BUILDDIR/sqlcipher/sqlite3.h" $BUILDDIR/pysqlcipher3/amalgamation

if [[ ! -d "$PYSQLCIPHER_DIR/include/sqlcipher" ]]; then
  mkdir -p "$PYSQLCIPHER_DIR/include/sqlcipher"
fi

cp "$BUILDDIR/sqlcipher/sqlite3.h" "$PYSQLCIPHER_DIR/include/sqlcipher"
