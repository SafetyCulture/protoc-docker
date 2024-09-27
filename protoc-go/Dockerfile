FROM golang:1.18.0-alpine as builder

#TODO @sc-lachlanrobertson: This is a tempoary item so I can test whether anything works!
ENV S12_PROTO_VERSION v1.32.1-0.20240926061402-edb34dfc0939

ENV PROTOC_GEN_GO_VERSION 1.34.1
ENV PROTOC_GEN_DOC_VERSION 1.5.1
ENV PROTOC_GEN_GO_GRPC_VERSION 1.4.0
ENV PROTOC_GEN_GO_VTPROTO_VERSION 0.6.0
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION 2.20.0

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.14.1
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
