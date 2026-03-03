#!/bin/bash

set -ex

# c.f. https://conda-forge.org/docs/maintainer/knowledge_base/#cross-compilation-examples
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

autoreconf --install --force

./configure --help

./configure \
    --prefix=$PREFIX \
    --enable-shared=yes \
    --enable-static=no \
    --disable-doxygen \
    --with-yoda=$PREFIX \
    --with-hepmc3=$PREFIX \
    --with-fastjet=$PREFIX \
    --with-fjcontrib=$PREFIX \
    --with-hdf5=$PREFIX/bin/h5cc \
    --with-highfive=$PREFIX \
    --with-zlib=$PREFIX \
    PYTHON=$PYTHON

make --jobs="${CPU_COUNT}"

# Skip ``make check`` when cross-compiling
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  # On macOS, the Python import tests (testImport.sh, testCmdLine.sh) fail
  # during make check because core.so references libRivet.dylib via an
  # absolute install-prefix path that doesn't exist until make install.
  # Linux uses LD_LIBRARY_PATH to find the build-tree library instead.
  # The conda package tests verify the installed module works correctly.
  XFAIL_TESTS=""
  if [[ "$target_platform" == osx-* ]]; then
    XFAIL_TESTS="testImport.sh testCmdLine.sh"
  fi
  make check XFAIL_TESTS="$XFAIL_TESTS" || { cat test/test-suite.log; exit 1; }
fi
make install
make clean
