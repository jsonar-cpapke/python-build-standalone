#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -ex

ROOT=`pwd`

export PATH=${TOOLS_PATH}/${TOOLCHAIN}/bin:${TOOLS_PATH}/host/bin:$PATH

tar -xf openssl-${OPENSSL_VERSION}.tar.gz

pushd openssl-${OPENSSL_VERSION}

# Otherwise it gets set to /tools/deps/ssl by default.
case "${TARGET_TRIPLE}" in
    *apple*)
        EXTRA_FLAGS="--openssldir=/private/etc/ssl"
        ;;
    *)
        EXTRA_FLAGS="--openssldir=/etc/ssl"
        ;;
esac

# musl is missing support for various primitives.
# TODO disable secure memory is a bit scary. We should look into a proper
# workaround.
if [ "${CC}" = "musl-clang" ]; then
    EXTRA_FLAGS="${EXTRA_FLAGS} no-async -DOPENSSL_NO_ASYNC -D__STDC_NO_ATOMICS__=1 no-engine -DOPENSSL_NO_SECURE_MEMORY"
fi

# The -arch cflags confuse Configure. And OpenSSL adds them anyway.
# Strip them.
EXTRA_TARGET_CFLAGS=${EXTRA_TARGET_CFLAGS/\-arch arm64/}
EXTRA_TARGET_CFLAGS=${EXTRA_TARGET_CFLAGS/\-arch x86_64/}

EXTRA_FLAGS="${EXTRA_FLAGS} ${EXTRA_TARGET_CFLAGS}"

/usr/bin/perl ./Configure --prefix=/tools/deps ${OPENSSL_TARGET} no-shared no-tests enable-fips ${EXTRA_FLAGS}

make -j ${NUM_CPUS}
make -j ${NUM_CPUS} install_sw install_ssldirs install_fips DESTDIR=${ROOT}/out
#/build/out/tools/deps/bin/openssl fipsinstall -out /build/out/etc/ssl/fipsmodule.cnf -module /build/out/tools/deps/lib64/ossl-modules/fips.so
