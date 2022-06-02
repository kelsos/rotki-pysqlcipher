#!/usr/bin/env bash

WORKDIR=$PWD

# Go into the directory and build sqlcipher
cd sqlcipher || exit 1

echo "Compiling sqlcipher";

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS" \
  LDFLAGS="-lcrypto"

make

cd .. || exit 1

mkdir -p /tmp/pybuild/sqlcipher
cp -R sqlcipher /tmp/pybuild

cd pysqlcipher3 || exit 1

if [ -z "$(git status --porcelain)" ];
then
    echo "Applying setup patch"
    git apply ../patches/pysqlcipher3_linux.diff
fi


echo "Copying libcrypto"
if [[ -f /usr/lib/libcrypto.so.1.1 ]]; then
  cp /usr/lib/libcrypto.so.1.1 ../pysqlcipher3
elif [[ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ]]; then
  cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ../pysqlcipher3
else
  echo "no libcrypto detected"
  exit 1
fi


