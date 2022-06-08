#!/usr/bin/env bash

ARCH="$(uname -m)"
WORKDIR=$PWD

echo "Building OpenSSL"
cd openssl || exit 1

if [[ $ARCH == "arm64" ]]; then
  export MACOSX_DEPLOYMENT_TARGET=11.0
  ./Configure enable-rc5 zlib darwin64-arm64-cc no-asm no-shared> /dev/null
else
  export MACOSX_DEPLOYMENT_TARGET=10.9
  ./Configure darwin64-x86_64-cc no-shared > /dev/null
fi

make > /dev/null

cd "$WORKDIR/sqlcipher" || exit 1

echo "Creating SQLCipher amalgamation"

./configure \
  --enable-tempstore=yes \
  --disable-shared \
  --enable-static=yes \
  --with-crypto-lib=none \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -I$WORKDIR/openssl/include" \
  LDFLAGS="$WORKDIR/openssl/libcrypto.a" > /dev/null

make sqlite3.c > /dev/null

if [[ ! -d "$WORKDIR/amalgamation" ]]; then
  mkdir -p "$WORKDIR/amalgamation"
fi

cp sqlite3.c "$WORKDIR/amalgamation"
cp sqlite3.h "$WORKDIR/amalgamation"

if [[ ! -d "$WORKDIR/include" ]]; then
  mkdir -p "$WORKDIR/include/sqlcipher"
fi

cp sqlite3.h "$WORKDIR/include/sqlcipher"
