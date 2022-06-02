echo "Preparing to compile sqlcipher";
# Go into the directory and build sqlcipher
cd sqlcipher || exit 1

./configure \
  --enable-tempstore=yes \
  CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS" \
  LDFLAGS="-lcrypto"

make

cd ../pysqlcipher3 || exit 1

if [ -z "$(git status --porcelain)" ];
then
    echo "Applying setup patch"
    git apply ../patches/pysqlcipher3_linux.diff
fi

cp ../sqlcipher/.libs/libsqlcipher.so ../pysqlcipher3

if [[ -f /usr/lib/libcrypto.so.1.1 ]]; then
  cp /usr/lib/libcrypto.so.1.1 ../pysqlcipher3
elif [[ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ]]; then
  cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ../pysqlcipher3
else
  echo "no libcrypto detected"
  exit 1
fi


