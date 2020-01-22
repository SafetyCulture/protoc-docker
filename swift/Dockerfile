FROM swift:5.1 as swift_builder

ENV GRPC_RELEASE=1.0.0-alpha.9

ADD . /src
RUN /src/build.sh


FROM safetyculture/protoc:1.4.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

COPY --from=swift_builder /plugins /plugins
RUN ln -s /plugins/protoc-gen-swift /usr/bin/protoc-gen-swift
RUN ln -s /plugins/protoc-gen-grpc-swift /usr/bin/protoc-gen-grpc-swift
