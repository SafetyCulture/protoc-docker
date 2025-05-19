#!/usr/bin/env sh

set -o errexit

go install google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION}
go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@v${PROTOC_GEN_DOC_VERSION}
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION}
go install github.com/planetscale/vtprotobuf/cmd/protoc-gen-go-vtproto@v${PROTOC_GEN_GO_VTPROTO_VERSION}
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${PROTOC_GEN_GRPC_GATEWAY_VERSION}
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v${PROTOC_GEN_GRPC_GATEWAY_VERSION}
go install github.com/redpanda-data/protoc-gen-go-mcp/cmd/protoc-gen-go-mcp@latest@latest

go install github.com/SafetyCulture/protoc-gen-ratelimit/cmd/protoc-gen-ratelimit@latest
go install github.com/SafetyCulture/protoc-gen-workato/cmd/protoc-gen-workato@latest
go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-govalidator@v${S12_PROTO_VERSION}
go install github.com/SafetyCulture/s12-proto/protobuf/protoc-gen-s12perm@v${S12_PROTO_VERSION}
