FROM safetyculture/protoc
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.17
ENV GOLANG_CHECKSUM 3a70e5055509f347c0fb831ca07a2bf3b531068f349b14a3c652e9b5b67beb5d
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV S12_PROTO_VERSION 1.13.1

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh
