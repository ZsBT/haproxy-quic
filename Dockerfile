ARG GNUDIST=debian:13
ARG DEBIAN_FRONTEND=noninteractive

ARG HAPROXY_VERSION=3.2
ARG LUA_VERSION=5.4

ARG SSL_DIR=/opt/quictls
ARG SSL_SRC=/usr/local/src/libssl
ARG HPR_SRC=/usr/local/src/haproxy


FROM ${GNUDIST} AS builder
ARG HAPROXY_VERSION
ARG HAPROXY_MAKE_ARGS
ARG LUA_VERSION
ARG SSL_SRC
ARG SSL_DIR
ARG HPR_SRC

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update
RUN apt-get install -y git time ca-certificates build-essential cmake g++ gcc libc6-dev liblua${LUA_VERSION}-dev libpcre2-dev libssl-dev libsystemd-dev make wget zlib1g-dev socat >/dev/null

# build QuicTLS
RUN git clone --quiet --single-branch --depth=1 https://github.com/quictls/quictls ${SSL_SRC}
RUN mkdir -vp ${SSL_DIR}/lib 
WORKDIR ${SSL_SRC}
RUN cmake . > configure-libssl.log
RUN make > make-libssl.log
RUN cp -r include ${SSL_DIR}/include
RUN cp -vt ${SSL_DIR}/lib/ *.so

# build HAProxy
RUN git clone --quiet --single-branch --depth=1 https://git.haproxy.org/git/haproxy-${HAPROXY_VERSION}.git/  ${HPR_SRC}
WORKDIR ${HPR_SRC}
RUN make -j$(nproc)  ${HAPROXY_MAKE_ARGS} \
  TARGET=linux-glibc \
  USE_LUA=1 \
  USE_OPENSSL=1 \
  USE_PCRE2=1 \
  USE_ZLIB=1 \
  USE_PROMEX=1 \
  USE_QUIC=1 \
  SSL_INC=${SSL_DIR}/include \
  SSL_LIB=${SSL_DIR}/lib \
  LDFLAGS="-Wl,-rpath,${SSL_DIR}/lib"	> make-haproxy.log

RUN make install-bin  > install-haproxy.log


# Final flat image
FROM ${GNUDIST}
ARG GNUDIST
ARG HAPROXY_VERSION
ARG LUA_VERSION
ARG OPTIONAL_PACKAGES="iputils-ping"
ARG SSL_DIR

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update
RUN apt-get install -y libc6 liblua${LUA_VERSION}-0 libpcre2-posix* zlib1g socat libsystemd0 ${OPTIONAL_PACKAGES} >/dev/null
RUN apt-get clean; find /var/lib/apt/lists -type f -delete

RUN mkdir -vp /run/haproxy
RUN groupadd -g 135 haproxy
RUN useradd -u 126 -g haproxy -m -d /var/lib/haproxy haproxy
RUN chown -v haproxy /run/haproxy
WORKDIR /var/lib/haproxy

COPY --from=builder /usr/local/sbin/haproxy /usr/local/sbin/
COPY --from=builder ${SSL_DIR}/lib ${SSL_DIR}/lib
ARG ETCHAPROXY=etc	# what to copy to /etc/haproxy
COPY $ETCHAPROXY /etc/haproxy

RUN echo ${SSL_DIR}/lib >> /etc/ld.so.conf
RUN ldconfig
RUN haproxy -vv

ENV HAPROXY_CONFIG=/etc/haproxy/haproxy.cfg

ENTRYPOINT haproxy -f $HAPROXY_CONFIG

LABEL org.opencontainers.image.description="HAProxy ${HAPROXY_VERSION} custom build with latest QUIC tls" 
LABEL org.opencontainers.image.title="HAProxy QUIC"
LABEL org.opencontainers.image.authors="ZsBT"
LABEL org.opencontainers.image.source="https://github.com/ZsBT/haproxy-quic/"
LABEL org.opencontainers.image.licences="WTFPL"
LABEL org.opencontainers.image.version="1.6" 
LABEL com.github.zsbt.haproxy.baseimage="${GNUDIST}"
LABEL com.github.zsbt.haproxy.version="${HAPROXY_VERSION}" 
LABEL com.github.zsbt.haproxy.luaversion="${LUA_VERSION}"
