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
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$RECIPE_DIR:$PATH"
        export CC="cl_wrapper.py"
        export RANLIB=llvm-ranlib
        export AS=llvm-as
        export AR=llvm-ar
        export LD=link
        export CFLAGS="-MD -I$PREFIX/Library/include -O2 -Dstrcasecmp=_stricmp"
        export CXXFLAGS="-MD -I$PREFIX/Library/include -O2 -Dstrcasecmp=_stricmp"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib -no-undefined gdi32.lib $PREFIX/Library/lib/pthreads.lib user32.lib"
        for sh_file in test-hwloc-annotate.sh test-hwloc-calc.sh test-hwloc-diffpatch.sh test-hwloc-distrib.sh test-hwloc-compress-dir.sh; do
            # ignore CR LF differences
            sed -i "s|@HWLOC_DIFF_U@|@HWLOC_DIFF_U@ --strip-trailing-cr|g" utils/hwloc/$sh_file.in
        done
        # Skip failing tests that are skipped on Linux x86_64 and OSX, but not skipped on windows
        sed -i "s|SUBDIRS += x86||g" tests/hwloc/Makefile.am
        autoreconf -i
        chmod +x configure
        ./configure --prefix="$PREFIX/Library" --libdir="$PREFIX/Library/lib" $DISABLES
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
