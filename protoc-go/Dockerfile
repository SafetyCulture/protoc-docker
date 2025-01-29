FROM golang:1.23.0-alpine as builder

ENV S12_PROTO_VERSION 1.34.0

ENV PROTOC_GEN_GO_VERSION 1.36.4
ENV PROTOC_GEN_DOC_VERSION 1.5.1
# This isn't the same as the repo version, run `go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && protoc-gen-go-grpc --version` to find the version
ENV PROTOC_GEN_GO_GRPC_VERSION 1.5.1
ENV PROTOC_GEN_GO_VTPROTO_VERSION 0.6.0
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION 2.26.0

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.15.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
