FROM ghcr.io/safetyculture/protoc:1.14.2
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_WEB_RELEASE 1.0.4

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
