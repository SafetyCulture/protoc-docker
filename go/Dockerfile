FROM safetyculture/protoc
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.12.5
ENV GOLANG_CHECKSUM 2aa5f088cbb332e73fc3def546800616b38d3bfe6b8713b8a6404060f22503e8
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh
