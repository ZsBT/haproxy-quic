#!/bin/bash

build_wolfssl()(
    set -ex

    WOLFSSL_BRANCH=v5.8.2-stable 

    git clone --depth 1 --branch $WOLFSSL_BRANCH https://github.com/wolfssl/wolfssl.git ${SSL_SRC}
    cd ${SSL_SRC}
    ./autogen.sh >autogen-wolfssl.log
    ./configure TARGET=linux-glibc --with-gnu-ld EXTRA_CFLAGS=-DWOLFSSL_GETRANDOM=1 \
        --enable-haproxy ${SSL_MAKE_ARGS} --prefix=${SSL_DIR} --libdir=${SSL_DIR}/lib \
        --enable-tls13 --disable-oldtls  \
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
    ./Configure --libdir=lib --prefix=${SSL_DIR} > configure-openssl.log
    make -j $(nproc) ${SSL_MAKE_ARGS} > make-openssl.log
    make install	> install-openssl.log
)



build_$1

