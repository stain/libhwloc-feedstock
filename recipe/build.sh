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
        export CFLAGS="-MD -I$PREFIX/Library/include -O2 -Dstrcasecmp=_stricmp"
        export CXXFLAGS="-MD -I$PREFIX/Library/include -O2 -Dstrcasecmp=_stricmp"
        export CPATH="$PREFIX/Library/include"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib -no-undefined"
        autoreconf -i
        chmod +x configure
        sed -i "s/-Wl,-DLL,-IMPLIB/-link -DLL -IMPLIB/g" configure
        sed -i "s|--output-def -Xlinker .libs/libhwloc.def|-def:.libs/libhwloc.def|g" hwloc/Makefile.in
        sed -i "s|--output-def -Xlinker .libs/libhwloc.def|-def:.libs/libhwloc.def|g" hwloc/Makefile.am
        for sh_file in test-hwloc-annotate.sh test-hwloc-calc.sh test-hwloc-diffpatch.sh test-hwloc-distrib.sh test-hwloc-compress-dir.sh; do
            # ignore CR LF differences
            sed -i "s|diff -u|diff --strip-trailing-cr -u|g" utils/hwloc/$sh_file
        done
        sed -i "s|#include <unistd.h>||g" "doc/examples/cpuset+bitmap+cpubind.c"
        sed -i "s|#include <unistd.h>||g" "doc/examples/nodeset+membind+policy.c"
        sed -i "s|#include <unistd.h>|#define pid_t int|g" "doc/examples/shared-caches.c"
        sed -i "s|SUBDIRS += x86||g" tests/hwloc/Makefile.am

        ./configure --prefix="$PREFIX/Library" --libdir="$PREFIX/Library/lib" $DISABLES
        make -j${CPU_COUNT} V=1 LDFLAGS="$LDFLAGS gdi32.lib $PREFIX/Library/lib/pthreads.lib user32.lib"
        ;;
esac

make -j${CPU_COUNT}
make check -j${CPU_COUNT}
make install

PROJECT=hwloc
if [[ `uname` == MINGW* ]]; then
    LIBRARY_LIB=$PREFIX/Library/lib
    mv "${LIBRARY_LIB}/${PROJECT}.dll.lib" "${LIBRARY_LIB}/${PROJECT}.lib"
fi
