FROM safetyculture/protoc:1.4.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_RELEASE 1.20.1

# install dependencies
ADD . /src
RUN /src/build.sh
