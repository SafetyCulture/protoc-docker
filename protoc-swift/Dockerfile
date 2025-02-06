FROM swift:5.2 as swift_builder

ENV GRPC_RELEASE=1.7.3

ADD . /src
RUN /src/build.sh

FROM ghcr.io/safetyculture/protoc:1.15.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

COPY --from=swift_builder /plugins /plugins
RUN ln -s /plugins/protoc-gen-swift /usr/bin/protoc-gen-swift
RUN ln -s /plugins/protoc-gen-grpc-swift /usr/bin/protoc-gen-grpc-swift
