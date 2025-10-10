ARG GNUDIST=debian:13

ARG HAPROXY_VERSION=3.2
ARG LUA_VERSION=5.4

ARG OPTIONAL_PACKAGES="iputils-ping"

# wolfssl, quictls_quictls, quictls_openssl
ARG SSL_VENDOR=wolfssl
ARG SSL_MAKE_ARGS

ARG SSL_DIR=/usr/local
ARG SSL_SRC=/usr/local/src/libssl



FROM ${GNUDIST} AS builder

ARG HAPROXY_VERSION
ARG HAPROXY_MAKE_ARGS
ARG LUA_VERSION
ARG SSL_VENDOR
ARG SSL_MAKE_ARGS
ARG SSL_SRC
ARG SSL_DIR

ENV SSL_MAKE_ARGS=${SSL_MAKE_ARGS}
ENV SSL_DIR=${SSL_DIR}
ENV SSL_SRC=${SSL_SRC}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update
RUN apt-get -qq install -y git time ca-certificates build-essential cmake g++ gcc libc6-dev liblua${LUA_VERSION}-dev libpcre2-dev libssl-dev libsystemd-dev make wget zlib1g-dev socat

COPY build-ssl.sh /usr/local/bin/
RUN build-ssl.sh ${SSL_VENDOR}

ENV HAPROXY_VERSION=${HAPROXY_VERSION}
ENV HAPROXY_MAKE_ARGS=${HAPROXY_MAKE_ARGS}
COPY build-haproxy.sh /usr/local/bin
RUN build-haproxy.sh ${SSL_VENDOR}


# Final flat image
FROM ${GNUDIST}
ARG GNUDIST
ARG HAPROXY_VERSION
ARG LUA_VERSION
ARG OPTIONAL_PACKAGES
ARG SSL_DIR
ARG SSL_VENDOR

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update
RUN apt-get -qq install -y libc6 liblua${LUA_VERSION}-0 libpcre2-posix* zlib1g socat libsystemd0 ${OPTIONAL_PACKAGES}
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

ENTRYPOINT [ "haproxy", "-f", "/etc/haproxy/haproxy.cfg" ]

LABEL org.opencontainers.image.description="HAProxy ${HAPROXY_VERSION} custom build with latest QUIC tls" 
LABEL org.opencontainers.image.title="HAProxy QUIC"
LABEL org.opencontainers.image.authors="ZsBT"
LABEL org.opencontainers.image.source="https://github.com/ZsBT/haproxy-quic/"
LABEL org.opencontainers.image.licences="WTFPL"
LABEL org.opencontainers.image.version="1.7"
LABEL com.github.zsbt.haproxy.baseimage="${GNUDIST}"
LABEL com.github.zsbt.haproxy.version="${HAPROXY_VERSION}" 
LABEL com.github.zsbt.haproxy.luaversion="${LUA_VERSION}"
LABEL com.github.zsbt.haproxy.ssl.vendor="${SSL_VENDOR}"

