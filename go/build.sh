#!/usr/bin/env sh

set -e

apk add --no-cache --virtual .go_build bash gcc musl-dev openssl go git

export GOROOT_BOOTSTRAP="$(go env GOROOT)"
export GOOS="$(go env GOOS)"
export GOARCH="$(go env GOARCH)"
export GO386="$(go env GO386)"
export GOARM="$(go env GOARM)"
export GOHOSTOS="$(go env GOHOSTOS)"
export GOHOSTARCH="$(go env GOHOSTARCH)"

curl -o go.tgz -L https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
echo 'a4ab229028ed167ba1986825751463605264e44868362ca8e7accc8be057e993 *go.tgz' | sha256sum -c -
tar -C /usr/local -xzf go.tgz
rm go.tgz

cd /usr/local/go/src
for p in /go-alpine-patches/*.patch; do
  [ -f "$p" ] || continue
  patch -p2 -i "$p"
done

./make.bash

mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
go get -u github.com/golang/protobuf/protoc-gen-go
go get -u github.com/gogo/protobuf/protoc-gen-gogo

go get -u github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator
go get -u github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-logger
go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

rm -rf /go-alpine-patches
apk del .go_build

go version
