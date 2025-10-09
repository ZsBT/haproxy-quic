#!/bin/bash

case ${SSL_VENDOR} in

    wolfssl)
        HAPROXY_MAKE_ARGS+="USE_OPENSSL_WOLFSSL=1"
        ;;

    quictls*)
        HAPROXY_MAKE_ARGS+="USE_OPENSSL=1"
        ;;
esac

set -ex

# build HAProxy
git clone --quiet --single-branch --depth=1 https://git.haproxy.org/git/haproxy-${HAPROXY_VERSION}.git/  /usr/src/haproxy
cd /usr/src/haproxy
make -j$(nproc)  ${HAPROXY_MAKE_ARGS} \
  TARGET=linux-glibc \
  USE_LIBCRYPT=1 \
  USE_LUA=1 \
  USE_PCRE2=1 \
  USE_ZLIB=1 \
  USE_PROMEX=1 \
  USE_QUIC=1 \
  SSL_INC=${SSL_DIR}/include \
  SSL_LIB=${SSL_DIR}/lib \
  LDFLAGS="-Wl,-rpath,${SSL_DIR}/lib"	> make-haproxy.log

make install-bin  > install-haproxy.log
