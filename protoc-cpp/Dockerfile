FROM ghcr.io/safetyculture/protoc:1.15.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

# TODO: Update to new s12-proto release tag with protobuf v24 compatibility
ENV CRUX_CLIENT_RELEASE=1.36.0

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
