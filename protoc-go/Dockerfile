FROM golang:1.18.0-alpine as builder

ENV GRPC_GATEWAY_VERSION 2.18.0
ENV S12_PROTO_VERSION 1.31.0

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.14.1
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
