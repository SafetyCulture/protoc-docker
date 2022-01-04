#!/usr/bin/env sh

set -e

apk add --no-cache --virtual .go_build bash gcc musl-dev openssl go git

curl -o go.tgz -L https://dl.google.com/go/go$GOLANG_VERSION.src.tar.gz

echo "$GOLANG_CHECKSUM *go.tgz" | sha256sum -c -
tar -C /usr/local -xzf go.tgz
rm go.tgz

cd /usr/local/go/src
./make.bash

go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/planetscale/vtprotobuf/cmd/protoc-gen-go-vtproto@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest

go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator@v$S12_PROTO_VERSION
go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-s12perm@v$S12_PROTO_VERSION
go install github.com/SafetyCulture/protoc-gen-ratelimit/cmd/protoc-gen-ratelimit@latest
go install github.com/SafetyCulture/protoc-gen-workato/cmd/protoc-gen-workato@latest

go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest

rm -rf $GOPATH/pkg/mod
apk del .go_build

go version
