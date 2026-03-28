FROM alpine:3.21
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.21/community protoc grpc grpc-plugins
RUN mkdir /defs

COPY --from=bufbuild/buf:1.66.0 /usr/local/bin/buf /usr/local/bin/buf

# Setup directories for the volumes that should be used
WORKDIR /defs
