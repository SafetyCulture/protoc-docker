#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++
apk add --no-cache --virtual .build git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake python autoconf automake libtool

# Install the protoc-gen-grpc-web
mkdir -p /usr/local/grpc-web
git clone https://github.com/grpc/grpc-web.git /usr/local/grpc-web
cd /usr/local/grpc-web
git checkout $GRPC_WEB_RELEASE
make install-plugin

apk del .build
