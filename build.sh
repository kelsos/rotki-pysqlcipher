#!/usr/bin/env bash

WORKDIR=$PWD
BUILDDIR=/tmp/pybuild

if [[ -d "$BUILDDIR" ]]; then
    echo "Warning $BUILDDIR exists"
    exit 1
fi

# Go into the directory and build sqlcipher
echo "Creating sqlcipher amalgamation";
mkdir -p "$BUILDDIR/sqlcipher"
cp -R sqlcipher "$BUILDDIR"
cd "$BUILDDIR/sqlcipher/" || exit 1

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS" \
  LDFLAGS="-lcrypto"

make sqlite3.c

cd "$WORKDIR" || exit 1
cp -R pysqlcipher3 "$BUILDDIR"
cd "$BUILDDIR/pysqlcipher3" || exit 1
echo "Applying pysqlcipher3 setup patch"
patch < "$WORKDIR/patches/pysqlcipher3_linux.diff"

if [[ ! -d "$BUILDDIR/pysqlcipher3/amalgamation" ]]; then
    mkdir "$BUILDDIR/pysqlcipher3/amalgamation"
fi

cp "$BUILDDIR/sqlcipher/sqlite3.c" $BUILDDIR/pysqlcipher3
cp "$BUILDDIR/sqlcipher/sqlite3.h" $BUILDDIR/pysqlcipher3

