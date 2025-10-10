[![build the image and publish on DockerHub](https://github.com/ZsBT/haproxy-quic/actions/workflows/docker-image.yml/badge.svg)](https://github.com/ZsBT/haproxy-quic/actions/workflows/docker-image.yml)

# haproxy-quic
HAproxy with HTTP/3 support.

Docker Hub images available: [buffertly/haproxy-quic](https://hub.docker.com/r/buffertly/haproxy-quic)

<details>
  <summary>The image has a couple of tags.</summary>

  - `wolfssl`, `latest`: based on https://github.com/wolfSSL/wolfssl : x86_64 and armv8 architectures included.
  - `quictls`: based on https://github.com/quictls/quictls : for x86_64 CPU only.
  - `openssl`, `stable`: based on https://github.com/quictls/openssl (discontinued in Sep 2024). x86_64 and armv8.
</details>


<details>
  <summary>Optional build args</summary>


  GNUDIST: The GNU Linux docker base image.

  LUA_VERSION: The required Lua version.

  HAPROXY_VERSION: The HAProxy version.

  OPTIONAL_PACKAGES: OS packages you need in the container, separated with spaces. Default: `iputils-ping`

  HAPROXY_MAKE_ARGS: Arguments to add to `make` while building HAProxy
 
  SSL_VENDOR: one of wolfssl, quictls_quictls, quictls_openssl
  
  SSL_MAKE_ARGS: additional make arguments while building ssl
  
</details>
