#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++
apk add --no-cache --virtual .build protobuf-dev libprotobuf libprotoc git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake autoconf automake libtool

# Install the protoc-gen-cruxclient plugin
mkdir -p /usr/local/cruxclient
git clone https://github.com/SafetyCulture/s12-proto.git /usr/local/cruxclient
cd /usr/local/cruxclient
git checkout v$CRUX_CLIENT_RELEASE
make install-cruxclient

rm -rf /usr/local/cruxclient
apk del .build
