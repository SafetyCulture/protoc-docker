FROM safetyculture/protoc
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.16.1
ENV GOLANG_CHECKSUM 680a500cd8048750121677dd4dc055fdfd680ae83edc7ed60a4b927e466228eb
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV S12_PROTO_VERSION 1.12.5

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh
