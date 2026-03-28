#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++
apk add --no-cache --virtual .build protobuf-dev abseil-cpp-dev libprotobuf libprotoc git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake autoconf automake libtool pkgconf

# Install the protoc-gen-cruxclient plugin
mkdir -p /usr/local/cruxclient
git clone https://github.com/SafetyCulture/s12-proto.git /usr/local/cruxclient
cd /usr/local/cruxclient
git checkout v$CRUX_CLIENT_RELEASE

# Regenerate wire_options.pb.cc/h to match the container's protobuf version
protoc -I protobuf/protoc-gen-cruxclient \
  --cpp_out=protobuf/protoc-gen-cruxclient/ \
  protobuf/protoc-gen-cruxclient/wire_options.proto

make install-cruxclient

rm -rf /usr/local/cruxclient
apk del .build
