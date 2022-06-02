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

cat setup.py

cp ..sqlcipher/.libs/libsqlcipher.so ../pysqlcipher3
cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 ../pysqlcipher