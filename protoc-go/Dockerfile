FROM golang:1.23.0-alpine as builder

ENV S12_PROTO_VERSION 1.37.0

ENV PROTOC_GEN_GO_VERSION 1.34.1
ENV PROTOC_GEN_DOC_VERSION 1.5.1
ENV PROTOC_GEN_GO_GRPC_VERSION 1.4.0
ENV PROTOC_GEN_GO_VTPROTO_VERSION 0.6.0
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION 2.20.0

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.14.2
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
