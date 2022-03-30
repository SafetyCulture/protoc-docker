FROM alpine:3.15
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

RUN apk add --no-cache protoc grpc
RUN mkdir /defs

# Setup directories for the volumes that should be used
WORKDIR /defs
