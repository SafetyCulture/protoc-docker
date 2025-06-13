FROM ghcr.io/safetyculture/protoc:1.14.1
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV CRUX_CLIENT_RELEASE 1.35.0

# install dependencies and build/install grpc plugin
ADD s12-proto /usr/local/cruxclient
ADD . /src
RUN /src/build.sh
