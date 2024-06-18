FROM golang:1.18.0-alpine as builder

ENV S12_PROTO_VERSION 1.29.0

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.14.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/ /usr/local/go/bin/
