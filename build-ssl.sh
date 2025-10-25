#!/bin/bash

WOLFSSL_BRANCH=v5.8.2-stable 

build_wolfssl()(
    set -ex

    git clone --depth 1 --branch $WOLFSSL_BRANCH https://github.com/wolfssl/wolfssl.git ${SSL_SRC}
    cd ${SSL_SRC}
    ./autogen.sh >autogen-wolfssl.log
    ./configure TARGET=linux-glibc --with-gnu-ld EXTRA_CFLAGS=-DWOLFSSL_GETRANDOM=1 \
        --enable-haproxy ${SSL_MAKE_ARGS} --prefix=${SSL_DIR} --libdir=${SSL_DIR}/lib \
        --disable-benchmark --disable-examples --disable-crypttests --disable-crypttests-libs \
        --enable-64bit \
        --enable-tls13 --disable-oldtls  \
        --enable-aesxts --enable-cmac --enable-curve25519 --enable-ed25519 --enable-ed25519-stream --enable-curve448 --enable-ed448 --enable-ed448-stream \
        --enable-ocsp --enable-ocspstapling --enable-ocspstapling2 \
        --enable-crl \
        --enable-alpn --enable-quic --enable-earlydata \
    >configure-wolfssl.log
    # --enable-fips
    make -j$(nproc) >make-wolfssl.log
    make test
    make install
)


build_quictls_quictls()(
    set -ex

    git clone --quiet --single-branch --depth=1 https://github.com/quictls/quictls ${SSL_SRC}
    mkdir -vp ${SSL_DIR}/lib 
    cd ${SSL_SRC}
    cmake . > configure-libssl.log
    make -j$(nproc) ${SSL_MAKE_ARGS} crypto-static ssl-static > make-libssl.log
    cp -art ${SSL_DIR}/include/ include/*
    cp  -avt ${SSL_DIR}/lib/ *.so
)


build_quictls_openssl()(
    set -ex

    git clone --quiet --single-branch --depth 1 https://github.com/quictls/openssl ${SSL_SRC}
    cd ${SSL_SRC}
    mkdir -p ${SSL_DIR}
    ./Configure --libdir=lib --prefix=${SSL_DIR} -w no-tests no-unit-test no-uplink no-acvp-tests no-weak-ssl-ciphers no-deprecated no-des no-bf no-cast no-rc2 no-rc4 no-rc5 no-seed no-md2 no-mdc2 no-ripemd
    make -j $(nproc) ${SSL_MAKE_ARGS} build_libs > make-openssl.log
    cp -art ${SSL_DIR}/include/ include/*
    cp -avt ${SSL_DIR}/lib/ *.so

)



build_$1

