#!/usr/bin/env sh

set -e

apt-get -q update
apt-get -q install -y libz-dev unzip patch patchelf

# Install the protoc-gen-swift protoc-gen-swiftgrpc plugins
mkdir -p /usr/local/grpc
git clone https://github.com/grpc/grpc-swift /usr/local/grpc
cd /usr/local/grpc
git checkout $GRPC_RELEASE
make plugin

mkdir -p /plugins
cp /usr/local/grpc/protoc-gen-swift /usr/local/grpc/protoc-gen-grpc-swift /plugins

cp /lib64/ld-linux-x86-64.so.2 $(ldd /plugins/protoc-gen-swift | awk '{print $3}' | grep /lib | sort | uniq) /plugins/

find /plugins/ -name 'lib*.so*' -exec patchelf --set-rpath /plugins {} \;

for p in protoc-gen-swift protoc-gen-grpc-swift; do
  patchelf --set-interpreter /plugins/ld-linux-x86-64.so.2 --set-rpath /plugins /plugins/${p}; \
done
