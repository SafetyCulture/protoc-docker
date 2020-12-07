FROM safetyculture/protoc
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.15.2
ENV GOLANG_CHECKSUM 28bf9d0bcde251011caae230a4a05d917b172ea203f2a62f2c2f9533589d4b4d
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV S12_PROTO_VERSION 1.12.3

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh
