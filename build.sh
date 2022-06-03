#!/usr/bin/env bash

WORKDIR=$PWD
BUILDDIR=/tmp/pybuild
SQLCIPHER_DIR="$BUILDDIR/sqlcipher"
PYSQLCIPHER_DIR="$BUILDDIR/pysqlcipher3"

if [[ -d "$BUILDDIR" ]]; then
    echo "Warning $BUILDDIR exists"
    exit 1
fi

# Go into the directory and build sqlcipher
echo "Creating sqlcipher amalgamation";
mkdir -p "$SQLCIPHER_DIR"
cp -R sqlcipher "$BUILDDIR"
cd "$SQLCIPHER_DIR" || exit 1

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS" \
  LDFLAGS="-lcrypto"

make sqlite3.c

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

if [[ ! -d "$PYSQLCIPHER_DIR/includes/sqlcipher" ]]; then
  mkdir -p "$PYSQLCIPHER_DIR/includes/sqlcipher"
fi

cp "$BUILDDIR/sqlcipher/sqlite3.h" "$PYSQLCIPHER_DIR/includes/sqlcipher"
