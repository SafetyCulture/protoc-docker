#!/usr/bin/env sh

set -e

apk --update --no-cache add bash curl
apk --no-cache add --virtual .pb-build make cmake autoconf automake tar libtool g++

mkdir -p /tmp/protobufs
cd /tmp/protobufs
curl -o protobufs.tar.gz -L https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protobuf-cpp-${PROTOC_VERSION}.tar.gz
mkdir -p protobuf
tar -zxvf protobufs.tar.gz -C /tmp/protobufs/protobuf --strip-components=1
cd protobuf
./autogen.sh
./configure --prefix=/usr
make
make install

cd
rm -rf /tmp/protobufs/

apk --no-cache add libstdc++
apk del .pb-build
rm -rf /var/cache/apk/*

mkdir /defs
