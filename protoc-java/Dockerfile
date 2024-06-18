FROM ubuntu:16.04 as javalite_builder
RUN apt-get update && \
    apt-get install -y bash patch curl patchelf

FROM ghcr.io/safetyculture/protoc:1.14.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_JAVA_VERSION=1.27.0

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
