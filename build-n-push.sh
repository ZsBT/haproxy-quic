#!/bin/bash

DIST=debian
CODE=bullseye

IMG=buffertly/haproxy-quic
TAG=$CODE

set -ex

docker build -t $IMG:$TAG --build-arg GNUDIST=${DIST}:${CODE}  .
docker tag $IMG:$TAG $IMG:latest

docker push $IMG:$TAG
docker push $IMG:latest

