FROM ubuntu:16.04 as javalite_builder
RUN apt-get update && \
    apt-get install -y bash patch curl patchelf
ENV PROTOC_GEN_JAVALITE_VERSION=3.11.2
RUN mkdir -p /protoc-gen-javalite && \
    curl -L https://repo1.maven.org/maven2/com/google/protobuf/protoc-gen-javalite/${PROTOC_GEN_JAVALITE_VERSION}/protoc-gen-javalite-${PROTOC_GEN_JAVALITE_VERSION}-linux-x86_64.exe > /protoc-gen-javalite/protoc-gen-javalite && \
    chmod 755 /protoc-gen-javalite/protoc-gen-javalite
RUN cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-javalite/protoc-gen-javalite | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-javalite/
RUN find /protoc-gen-javalite/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-javalite {} \; && \
    for p in protoc-gen-javalite; do \
        patchelf --set-interpreter /protoc-gen-javalite/ld-linux-x86-64.so.2 --set-rpath /protoc-gen-javalite /protoc-gen-javalite/${p}; \
    done

FROM ghcr.io/safetyculture/protoc:1.12.0
LABEL maintainer="SafetyCulture <info@safetyculture.io>"

ENV GRPC_JAVA_VERSION=1.27.0

# install dependencies and build/install grpc plugin
ADD . /src
RUN /src/build.sh

COPY --from=javalite_builder /protoc-gen-javalite /protoc-gen-javalite
RUN ln -s /protoc-gen-javalite/protoc-gen-javalite /usr/bin/protoc-gen-javalite
