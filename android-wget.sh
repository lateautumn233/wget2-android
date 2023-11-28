#!/bin/bash

BASE_PATH=$(cd "$(dirname "$0")" && pwd)


APP_ABI=(armeabi-v7a arm64-v8a x86-64)
ANDROID_NDK_VERSION="24"
LIBS_INSTALL_DIR="/usr/local"
APT_PACKAGES="git autoconf autoconf-archive autopoint automake autogen libtool make flex bison gettext gperf ca-certificates wget patch texinfo gengetopt curl lzip pandoc rsync python3 binfmt-support bc texlive google-android-ndk-installer"

install_dependencies() {
    apt-get update -y && apt-get install --no-install-recommends -y $APT_PACKAGES
}


compile() {
    TARGET=$1
    ABI=$2
    
    export	PREFIX=$TARGET
    export INSTALLDIR="$LIBS_INSTALL_DIR/$PREFIX"
    export NDK_SRC=/usr/lib/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/ \
    CFLAGS="-I$INSTALLDIR/include" \
    LDFLAGS="-L$INSTALLDIR/lib" \
    PKG_CONFIG_PATH="$INSTALLDIR/lib/pkgconfig:/usr/$PREFIX/lib/pkgconfig"
    # Create a build directory and move into it
    BUILD_DIR="build_$TARGET"

    # CC=$NDK_SRC/bin/aarch64-linux-android21-clang ./configure --host=aarch64-linux-android --disable-shared --enable-static --prefix=$INSTALLDIR
    git clone https://git.lysator.liu.se/nettle/nettle.git --depth=1
    cd nettle
    bash .bootstrap
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    CC=$NDK_SRC/bin/$TARGET$ABI-clang ../configure --host=$TARGET --disable-shared --enable-static --prefix=$INSTALLDIR --enable-mini-gmp && \
    make -j$(nproc) && make install && rm -rf ../$BUILD_DIR
    cd $BASE_PATH
    
    wget -q -O- https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.2.tar.xz| tar x --xz
    cd gnutls-* 
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    CC=$NDK_SRC/bin/$TARGET$ABI-clang ../configure --host=$TARGET --disable-shared --enable-static --prefix=$INSTALLDIR --with-nettle-mini --with-included-libtasn1 \
	--with-included-unistring --without-p11-kit -disable-cxx --disable-tools --disable-doc --disable-tests && \
    make -j$(nproc) && make install && rm -rf ../$BUILD_DIR
    cd $BASE_PATH
    
    git clone https://gitlab.com/gnuwget/wget2.git --depth=1
    cd wget2
    ./bootstrap --skip-po
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    CC=$NDK_SRC/bin/$TARGET$ABI-clang ../configure --host=$TARGET --disable-shared --enable-static --prefix=$INSTALLDIR --without-libpcre2  --without-libpcre && \
    make -j$(nproc) && make install && rm -rf ../$BUILD_DIR
    cd $BASE_PATH
}

install_dependencies

compile "aarch64-linux-android" "24"
compile "armv7a-linux-androideabi" "24"
compile "i686-linux-android" "24"
compile "x86_64-linux-android" "24"