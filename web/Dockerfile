FROM safetyculture/protoc:1.1.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_WEB_RELEASE 1.0.3

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh
