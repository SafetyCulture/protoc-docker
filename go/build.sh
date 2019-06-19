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

export GO111MODULE=on
export GOPROXY=https://proxy.golang.org

go get -u github.com/golang/protobuf/protoc-gen-go
go get github.com/gogo/protobuf/protoc-gen-gogo@v1.2.0

go get github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator@v1.4.2
go get github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-logger@v1.4.2
go get github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-gogrpcmock@v1.4.2
go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

rm -rf $GOPATH/pkg/mod
apk del .go_build

go version
