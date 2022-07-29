FROM golang:1.18.0-alpine as builder

ENV S12_PROTO_VERSION 1.21.2

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.12.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV S12_PROTO_VERSION 1.21.2
ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
