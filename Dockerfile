ARG GNUDIST=debian:stable

ARG DEBIAN_FRONTEND=noninteractive

FROM ${GNUDIST} as builder

RUN apt -qq update
RUN apt install -y git time ca-certificates gcc libc6-dev liblua5.3-dev libpcre3-dev libssl-dev libsystemd-dev make wget zlib1g-dev socat >/dev/null

# Install OpenSSL-quic
RUN git clone --quiet --single-branch --depth 1 https://github.com/quictls/openssl /usr/local/src/openssl
WORKDIR /usr/local/src/openssl
RUN mkdir -p /opt/quictls/ssl
RUN ./Configure --libdir=lib --prefix=/opt/quictls	> configure-openssl.log
RUN make -j $(nproc)	> make-openssl.log
RUN make install	> install-openssl.log

# Install HAProxy
RUN git clone --quiet --single-branch --depth 1 https://github.com/haproxy/haproxy.git /usr/local/src/haproxy
WORKDIR /usr/local/src/haproxy
RUN make -j $(nproc) \
  TARGET=linux-glibc \
  USE_LUA=1 \
  USE_OPENSSL=1 \
  USE_PCRE=1 \
  USE_ZLIB=1 \
  USE_SYSTEMD=1 \
  USE_PROMEX=1 \
  USE_QUIC=1 \
  SSL_INC=/opt/quictls/include \
  SSL_LIB=/opt/quictls/lib \
  LDFLAGS="-Wl,-rpath,/opt/quictls/lib"	> make-haproxy.log

RUN make install-bin  > install-haproxy.log

# Final flat image
FROM ${GNUDIST}

RUN apt -qq update
RUN apt install -y libc6 liblua5.3-0 libpcre3 zlib1g socat libsystemd0 >/dev/null
RUN apt clean; find /var/lib/apt/lists -type f -delete

RUN mkdir -vp /run/haproxy
RUN groupadd -g 135 haproxy
RUN useradd -u 126 -g haproxy -m -d /var/lib/haproxy haproxy
RUN chown -v haproxy /run/haproxy
WORKDIR /var/lib/haproxy

COPY --from=builder /usr/local/sbin/haproxy /usr/local/sbin/
COPY --from=builder /opt/quictls/lib /opt/quictls/lib
COPY etc /etc/haproxy

RUN echo /opt/quictls/lib >> /etc/ld.so.conf
RUN ldconfig
RUN haproxy -vv

ENTRYPOINT haproxy -f /etc/haproxy/haproxy.cfg
