#!/usr/bin/env sh

set -o errexit

go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${GRPC_GATEWAY_VERSION}
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v${GRPC_GATEWAY_VERSION}
go install github.com/planetscale/vtprotobuf/cmd/protoc-gen-go-vtproto@v${PSEUDOMUTO_PROTOC_GEN_DOC_VERSION}
go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@v${PSEUDOMUTO_PROTOC_GEN_DOC_VERSION}
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${GOOGLE_PROTOC_GEN_GO_GRPC_VERSION}
go install google.golang.org/protobuf/cmd/protoc-gen-go@v${GOOGLE_PROTOBUF_VERSION}

go install github.com/SafetyCulture/protoc-gen-ratelimit/cmd/protoc-gen-ratelimit@latest
go install github.com/SafetyCulture/protoc-gen-workato/cmd/protoc-gen-workato@latest
go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator@v${S12_PROTO_VERSION}
go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-s12perm@v${S12_PROTO_VERSION}
