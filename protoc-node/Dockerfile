FROM ghcr.io/safetyculture/protoc:1.14.1
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

RUN apk add --no-cache npm

RUN npm install -g ts-protoc-gen @bufbuild/protoc-gen-es @bufbuild/protoc-gen-connect-es
