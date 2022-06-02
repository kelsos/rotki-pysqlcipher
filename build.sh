#!/usr/bin/env bash

WORKDIR=$PWD

if [[ -d "/tmp/pybuild/" ]]; then
    echo "Warning /tmp/pybuild exists"
    exit 1
fi

# Go into the directory and build sqlcipher
echo "Compiling sqlcipher";
mkdir -p /tmp/pybuild/sqlcipher
cp -R sqlcipher /tmp/pybuild
cd /tmp/pybuild//sqlcipher/ || exit 1

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS" \
  LDFLAGS="-lcrypto"

make

cd "$WORKDIR" || exit 1
cp -R pysqlcipher3 /tmp/pybuild
cd /tmp/pybuild/pysqlcipher3 || exit 1
echo "Applying pysqlcipher3 setup patch"
patch < "$WORKDIR/patches/pysqlcipher3_linux.diff"

echo "Copying libsqlcipher"
cp /tmp/pybuild/sqlcipher/.libs/libsqlcipher.so /tmp/pybuild/pysqlcipher3/

echo "Copying libcrypto"

if [[ -f /usr/lib/libcrypto.so.1.1 ]]; then
  cp /usr/lib/libcrypto.so.1.1 ../pysqlcipher3
elif [[ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ]]; then
  cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ../pysqlcipher3
else
  echo "no libcrypto detected"
  exit 1
fi


