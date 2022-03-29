FROM safetyculture/protoc:1.11.2
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.18.0
ENV GOLANG_CHECKSUM 2effcd898140da79a061f3784ca4f8d8b13d811fb2abe9dad2404442dabbdf7a
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV S12_PROTO_VERSION 1.20.0

COPY --from=golang:1.18.0-alpine /usr/local/go/ /usr/local/go/

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh
