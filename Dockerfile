ARG GNUDIST=debian:stable

FROM ${GNUDIST} as builder

RUN apt -qq update
RUN DEBIAN_FRONTEND=noninteractive apt install -y git time ca-certificates gcc libc6-dev liblua5.3-dev libpcre3-dev libssl-dev libsystemd-dev make wget zlib1g-dev socat >/dev/null


# Install OpenSSL-quic
WORKDIR /usr/local/src
RUN git clone --single-branch --depth 1 https://github.com/quictls/openssl
RUN mkdir -p /opt/quictls/ssl
WORKDIR /usr/local/src/openssl
RUN ./Configure --libdir=lib --prefix=/opt/quictls
RUN time make -j $(nproc) >/var/log/make-openssl.log
RUN make install

# Install HAProxy
WORKDIR /usr/local/src
RUN git clone --single-branch --depth 1 https://github.com/haproxy/haproxy.git
WORKDIR /usr/local/src/haproxy
RUN time make -j $(nproc) \
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
  LDFLAGS="-Wl,-rpath,/opt/quictls/lib" >/var/log/make-haproxy.log

RUN make install-bin  >/var/log/install-bin.log

FROM ${GNUDIST}
RUN apt -qq update
RUN DEBIAN_FRONTEND=noninteractive apt install -y libc6 liblua5.3-0 libpcre3 zlib1g socat libsystemd0 >/dev/null
RUN apt clean; find /var/lib/apt/lists -type f -delete

COPY --from=builder /usr/local/sbin/haproxy /usr/local/sbin/
COPY --from=builder /opt/quictls/lib /opt/quictls/lib

RUN echo /opt/quictls/lib >> /etc/ld.so.conf
RUN ldconfig
RUN groupadd haproxy
RUN useradd haproxy -g haproxy
RUN mkdir -vp /run/haproxy /var/lib/haproxy
WORKDIR /var/lib/haproxy
RUN haproxy -v

ENTRYPOINT haproxy -f /etc/haproxy/haproxy.cfg

