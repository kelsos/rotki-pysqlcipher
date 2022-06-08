#!/usr/bin/env bash

ARCH="$(uname -m)"
WORKDIR=$PWD
echo $_PYTHON_HOST_PLATFORM
echo $ARCH

ARCH_POSTFIX=$ARCH
if [[ $ARCH == 'x86_64' ]]; then
  ARCH_POSTFIX="x64-64"
fi

cp -R "openssl-$ARCH_POSTFIX" openssl

cd "sqlcipher" || exit 1

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
