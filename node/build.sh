#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++ npm
apk add --no-cache --virtual .build git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake python autoconf automake libtool

# Install the grpc_node_plugin
mkdir -p /usr/local/grpc
git clone https://github.com/grpc/grpc.git /usr/local/grpc
cd /usr/local/grpc
git checkout v$GRPC_RELEASE
git submodule update --init
make grpc_node_plugin
mv /usr/local/grpc/bins/opt/grpc_node_plugin  /usr/local/bin/grpc_node_plugin

npm install -g ts-protoc-gen
npm install @bufbuild/protoc-gen-es @bufbuild/protoc-gen-connect-web

apk del .build
rm -rf /usr/local/grpc
