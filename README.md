[![build the image and publish on DockerHub](https://github.com/ZsBT/haproxy-quic/actions/workflows/docker-image.yml/badge.svg)](https://github.com/ZsBT/haproxy-quic/actions/workflows/docker-image.yml)

# haproxy-quic
HAproxy with HTTP/3 support

Docker Hub image available: buffertly/haproxy-quic

<details>
  <summary>Optional build args</summary>


  GNUDIST: The GNU Linux docker base image. Default: `debian:stable`

  LUA_VERSION: Default: 5.4

  HAPROXY_VERSION: The HAProxy version

  OPTIONAL_PACKAGES: OS packages you need in the container, separated with spaces. Default: `iputils-ping`

  HAPROXY_MAKE_ARGS: Arguments to add to `make`
  
</details>
