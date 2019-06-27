#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++
apk add --no-cache --virtual .build git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake python autoconf automake libtool

# Install the grpc_cpp_plugin
mkdir -p /usr/local/grpc
git clone https://github.com/grpc/grpc.git /usr/local/grpc
cd /usr/local/grpc
git checkout v$GRPC_RELEASE
git submodule update --init
make grpc_cpp_plugin
mv /usr/local/grpc/bins/opt/grpc_cpp_plugin  /usr/local/bin/grpc_cpp_plugin
make grpc_node_plugin
mv /usr/local/grpc/bins/opt/grpc_node_plugin  /usr/local/bin/grpc_node_plugin

# Install the protoc-gen-cruxclient plugin
mkdir -p /usr/local/cruxclient
git clone https://github.com/SafetyCulture/s12-proto.git /usr/local/cruxclient
cd /usr/local/cruxclient
git checkout v$CRUX_CLIENT_RELEASE
make install-cruxclient

rm -rf /usr/local/grpc
rm -rf /usr/local/cruxclient
apk del .build
