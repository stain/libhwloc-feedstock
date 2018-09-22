#!/bin/bash

set -e

DISABLES="--disable-cairo --disable-opencl --disable-cuda --disable-nvml"
DISABLES="$DISABLES --disable-gl --disable-libnuma --disable-libudev"

chmod +x configure

case `uname` in
    Darwin)
        ./configure --prefix=$PREFIX $DISABLES
        ;;
    Linux)
        export LDFLAGS="${LDFLAGS} -Wl,--as-needed"
        ./configure --prefix=$PREFIX $DISABLES
        ;;
    MINGW*)
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$PATH"
        export CC=clang-cl
        export RANLIB=llvm-ranlib
        export AS=llvm-as
        export AR=llvm-ar
        export LD=link
        export CFLAGS="-MD -I$PREFIX/Library/include -O3"
        export CXXFLAGS="-MD -I$PREFIX/Library/include -O3"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib -no-undefined"
        autoreconf -i
        chmod +x configure
        sed -i "s/-Wl,-DLL,-IMPLIB/-link -DLL -IMPLIB/g" configure
        sed -i "s/--output-def /-def:/g" hwloc/Makefile.in
        sed -i "s/--output-def /-def:/g" hwloc/Makefile.am
        ./configure --prefix="$PREFIX/Library" --libdir="$PREFIX/Library/lib" $DISABLES
        ;;
esac

make -j${CPU_COUNT}
make check -j${CPU_COUNT}
make install

PROJECT=hwloc
if [[ `uname` == MINGW* ]]; then
    LIBRARY_LIB=$PREFIX/Library/lib
    mv "${LIBRARY_LIB}/${PROJECT}.lib" "${LIBRARY_LIB}/${PROJECT}_static.lib"
    mv "${LIBRARY_LIB}/${PROJECT}.dll.lib" "${LIBRARY_LIB}/${PROJECT}.lib"
fi
