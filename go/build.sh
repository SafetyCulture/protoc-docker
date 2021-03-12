#!/usr/bin/env sh

set -e

apk add --no-cache --virtual .go_build bash gcc musl-dev openssl go git

curl -o go.tgz -L https://dl.google.com/go/go$GOLANG_VERSION.src.tar.gz

echo "$GOLANG_CHECKSUM *go.tgz" | sha256sum -c -
tar -C /usr/local -xzf go.tgz
rm go.tgz

cd /usr/local/go/src
./make.bash

mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

go get google.golang.org/protobuf/cmd/protoc-gen-go
go get google.golang.org/grpc/cmd/protoc-gen-go-grpc
go get github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway
go get github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2

go get github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator@v$S12_PROTO_VERSION
go get github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-s12perm@v$S12_PROTO_VERSION

go get github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

rm -rf $GOPATH/pkg/mod
apk del .go_build

go version
