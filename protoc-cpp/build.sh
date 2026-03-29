#!/usr/bin/env sh

set -e

apk add --no-cache libstdc++
apk add --no-cache --virtual .build protobuf-dev abseil-cpp-dev libprotobuf libprotoc git openssl binutils-gold g++ gcc gnupg libgcc linux-headers make cmake autoconf automake libtool pkgconf

# Install the protoc-gen-cruxclient plugin
mkdir -p /usr/local/cruxclient
git clone https://github.com/SafetyCulture/s12-proto.git /usr/local/cruxclient
cd /usr/local/cruxclient
git checkout v$CRUX_CLIENT_RELEASE

# Regenerate wire_options.pb.cc/h using Alpine's system protoc (protoc-system = Alpine's protoc 24.4,
# which matches the protobuf-dev headers used to compile the plugin)
protoc-system -I protobuf/protoc-gen-cruxclient \
  --cpp_out=protobuf/protoc-gen-cruxclient/ \
  protobuf/protoc-gen-cruxclient/wire_options.proto

# TEMPORARY: Patch proto3 optional support into cruxclient generator.
# Without this, buf errors on 28+ proto files: "plugin cruxclient does not support required features".
# Remove this sed once s12-proto PR #155 is merged and CRUX_CLIENT_RELEASE is bumped.
sed -i 's/Generator() {}/Generator() {}\n  uint64_t GetSupportedFeatures() const override {\n    return FEATURE_PROTO3_OPTIONAL;\n  }/' \
  protobuf/protoc-gen-cruxclient/cruxclient_generator.cc

make install-cruxclient

rm -rf /usr/local/cruxclient
apk del .build
