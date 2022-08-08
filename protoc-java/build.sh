#!/usr/bin/env sh

set -e

apk add --no-cache --virtual .build protobuf-dev libprotobuf libprotoc g++ curl

# Install the protoc-gen-grpc-java plugin
mkdir -p /usr/local/grpc
curl -L https://github.com/grpc/grpc-java/archive/v${GRPC_JAVA_VERSION}.tar.gz | tar xvz --strip-components=1 -C /usr/local/grpc
cd /usr/local/grpc/compiler/src/java_plugin/cpp
g++ -I. -I/protobuf/src *.cpp -L/protobuf/src/.libs -lprotoc -lprotobuf -lpthread --std=c++0x -s -o protoc-gen-grpc-java
install -c protoc-gen-grpc-java /usr/local/bin/

apk del .build
