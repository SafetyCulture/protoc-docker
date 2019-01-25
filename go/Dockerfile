FROM safetyculture/protoc
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GOLANG_VERSION 1.11
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# https://golang.org/issue/14851 (Go 1.8 & 1.7)
# https://golang.org/issue/17847 (Go 1.7)
COPY *.patch /go-alpine-patches/

# install dependencies and build/install Go
ADD . /src
RUN /src/build.sh

COPY script.sh /opt/safetyculture/script.sh
ENTRYPOINT ["/opt/safetyculture/script.sh"]
