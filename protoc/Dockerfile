FROM alpine:3.21
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

# Install protoc and grpc plugins from Alpine packages
# Alpine's protoc (24.4) is kept as /usr/bin/protoc-system for plugin compilation
# Protoc 26.1 is installed as /usr/bin/protoc for code generation (matches crux's bundled protobuf)
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.21/community protoc grpc grpc-plugins \
    && mv /usr/bin/protoc /usr/bin/protoc-system

ARG TARGETARCH
RUN apk add --no-cache curl unzip \
    && ARCH=$(case "${TARGETARCH}" in arm64) echo "aarch_64";; amd64) echo "x86_64";; *) echo "${TARGETARCH}";; esac) \
    && curl -sL "https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-linux-${ARCH}.zip" -o /tmp/protoc.zip \
    && unzip -q /tmp/protoc.zip -d /tmp/protoc \
    && mv /tmp/protoc/bin/protoc /usr/bin/protoc \
    && rm -rf /tmp/protoc /tmp/protoc.zip \
    && apk del curl unzip

RUN mkdir /defs

COPY --from=bufbuild/buf:1.66.0 /usr/local/bin/buf /usr/local/bin/buf

# Setup directories for the volumes that should be used
WORKDIR /defs
