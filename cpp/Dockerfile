FROM safetyculture/protoc:1.1.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_RELEASE 1.14.2
ENV CRUX_CLIENT_RELEASE 1.1.0

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
