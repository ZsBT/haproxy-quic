# haproxy-quic
HAproxy with HTTP/3 support. Just mount the stuff under /etc/haproxy and it is ready to go.

Docker Hub images available: [buffertly/haproxy-quic](https://hub.docker.com/r/buffertly/haproxy-quic)

<details>
  <summary>The image has a couple of tags.</summary>

  - `aws-lc` ![AWS LC action](https://github.com/ZsBT/haproxy-quic/actions/workflows/aws-lc.yml/badge.svg): not compiled but just packaged thanks to haproxy.com/downloads
  - `wolfssl`, `latest` ![compile action](https://github.com/ZsBT/haproxy-quic/actions/workflows/compile.yml/badge.svg): based on https://github.com/wolfSSL/wolfssl : x86_64 and armv8 architectures included. 
  - `quictls` ![compile action](https://github.com/ZsBT/haproxy-quic/actions/workflows/compile.yml/badge.svg): based on https://github.com/quictls/quictls : for x86_64 CPU only.
  - ~~`openssl`, `stable`: based on https://github.com/quictls/openssl (discontinued in Sep 2024). x86_64 and armv8.~~ (BROKEN)
</details>


<details>
  <summary>Optional build args for compiled images.</summary>

  * `GNUDIST`: The GNU Linux docker base image.
  * `OPTIONAL_PACKAGES`: OS packages you need in the container, separated with spaces. Default: `iputils-ping`
  * `HAPROXY_VERSION`: The HAProxy version.
  * `HAPROXY_MAKE_ARGS`: Arguments to add to `make` while building HAProxy
  * `SSL_VENDOR`: one of wolfssl, quictls_quictls, quictls_openssl
  * `SSL_MAKE_ARGS`: additional make arguments while building ssl
  * `LUA_VERSION`: The required Lua version.

  For details, take a look at the Dockerfile.
  
</details>
