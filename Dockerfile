ARG GNUDIST=debian:stable
ARG DEBIAN_FRONTEND=noninteractive

ARG LUA_VERSION=5.4


FROM ${GNUDIST} as builder

ARG HAPROXY_VERSION=3.2
ARG HAPROXY_MAKE_ARGS
ARG LUA_VERSION

RUN apt-get -qq update
RUN apt-get install -y git time ca-certificates gcc libc6-dev liblua${LUA_VERSION}-dev libpcre3-dev libssl-dev libsystemd-dev make wget zlib1g-dev socat >/dev/null

# Install OpenSSL-quic
RUN git clone --quiet --single-branch --depth 1 https://github.com/quictls/openssl /usr/local/src/openssl
WORKDIR /usr/local/src/openssl
RUN mkdir -p /opt/quictls/ssl
RUN ./Configure --libdir=lib --prefix=/opt/quictls	> configure-openssl.log
RUN make -j $(nproc) > make-openssl.log
RUN make install	> install-openssl.log

# Install HAProxy
RUN git clone --quiet --single-branch https://git.haproxy.org/git/haproxy-${HAPROXY_VERSION}.git/  /usr/local/src/haproxy
WORKDIR /usr/local/src/haproxy
RUN make -j $(nproc)  ${HAPROXY_MAKE_ARGS} \
  TARGET=linux-glibc \
  USE_LUA=1 \
  USE_OPENSSL=1 \
  USE_PCRE=1 \
  USE_ZLIB=1 \
  USE_SYSTEMD=0 \
  USE_PROMEX=1 \
  USE_QUIC=1 \
  SSL_INC=/opt/quictls/include \
  SSL_LIB=/opt/quictls/lib \
  LDFLAGS="-Wl,-rpath,/opt/quictls/lib"	> make-haproxy.log

RUN make install-bin  > install-haproxy.log


# Final flat image
FROM ${GNUDIST}
ARG LUA_VERSION
ARG OPTIONAL_PACKAGES="iputils-ping"

RUN apt-get -qq update
RUN apt-get install -y libc6 liblua${LUA_VERSION}-0 libpcre3 zlib1g socat libsystemd0 ${OPTIONAL_PACKAGES} >/dev/null
RUN apt-get clean; find /var/lib/apt/lists -type f -delete

RUN mkdir -vp /run/haproxy
RUN groupadd -g 135 haproxy
RUN useradd -u 126 -g haproxy -m -d /var/lib/haproxy haproxy
RUN chown -v haproxy /run/haproxy
WORKDIR /var/lib/haproxy

COPY --from=builder /usr/local/sbin/haproxy /usr/local/sbin/
COPY --from=builder /opt/quictls/lib /opt/quictls/lib
ARG ETCHAPROXY=etc	# what to copy to /etc/haproxy
COPY $ETCHAPROXY /etc/haproxy

RUN echo /opt/quictls/lib >> /etc/ld.so.conf
RUN ldconfig
RUN haproxy -vv

ENV HAPROXY_CONFIG=/etc/haproxy/haproxy.cfg

ENTRYPOINT haproxy -f $HAPROXY_CONFIG

LABEL org.opencontainers.image.description="HAProxy ${HAPROXY_VERSION} custom build with latest QUIC tls" 
LABEL org.opencontainers.image.title="HAProxy QUIC"
LABEL org.opencontainers.image.authors="ZsBT"
LABEL org.opencontainers.image.source="https://github.com/ZsBT/haproxy-quic/"
LABEL org.opencontainers.image.licences="WTFPL"
LABEL org.opencontainers.image.version="1.5" 
LABEL com.github.zsbt.haproxy.baseimage="${GNUDIST}"
LABEL com.github.zsbt.haproxy.version="${HAPROXY_VERSION}" 
LABEL com.github.zsbt.haproxy.luaversion="${LUA_VERSION}"
