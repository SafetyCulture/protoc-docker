FROM safetyculture/protoc:1.6.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_RELEASE 1.40.0
ENV CRUX_CLIENT_RELEASE 1.15.3

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
