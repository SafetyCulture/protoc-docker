FROM ghcr.io/safetyculture/protoc:1.12.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV CRUX_CLIENT_RELEASE 1.15.3

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
