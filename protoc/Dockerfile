FROM alpine:3.15
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

CMD apk add --no-cache protoc grpc
CMD mkdir /defs

# Setup directories for the volumes that should be used
WORKDIR /defs
