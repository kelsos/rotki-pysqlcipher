#!/usr/bin/env bash

WORKDIR=$PWD

echo "Building OpenSSL"
cd openssl || exit 1
./config no-shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl \
  CPPFLAGS="${MANYLINUX_CPPFLAGS}" \
  CFLAGS="${MANYLINUX_CFLAGS} -fPIC" \
  CXXFLAGS="${MANYLINUX_CXXFLAGS} -fPIC" \
  LDFLAGS="${MANYLINUX_LDFLAGS} -fPIC" > /dev/null

make > /dev/null
make install_sw > /dev/null

cd "$WORKDIR/sqlcipher" || exit 1

echo "Creating SQLCipher amalgamation"

./configure \
  --enable-tempstore=yes \
  --disable-shared \
  --enable-static=yes \
  --with-crypto-lib=none \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -I/usr/local/ssl/include/" \
  LDFLAGS="/usr/local/ssl/lib/libcrypto.a" > /dev/null

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
