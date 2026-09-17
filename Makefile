.PHONY: default
default: help

.PHONY: protoc
protoc: ## Builds the protoc docker container and pushes to the registry
	$(call build,protoc)

.PHONY: cpp
cpp: ## Builds the protoc docker container for `cpp`
	$(call build,protoc-cpp)

.PHONY: go
go: ## Builds the protoc docker container for `go`
	$(call build,protoc-go)

.PHONY: java
java: ## Builds the protoc docker container for `java`
	$(call build,protoc-java)

.PHONY: node
node: ## Builds the protoc docker container for `node`
	$(call build,protoc-node)

.PHONY: swift
swift: ## Builds the protoc docker container for `swift`
	$(call build,protoc-swift)

.PHONY: web
web: ## Builds the protoc docker container for `web`
	$(call build,protoc-web)

REGISTRY=ghcr.io/safetyculture

.PHONY: build
build = echo "Building Docker container $(1)"; docker build --no-cache -t $(REGISTRY)/$(1):$(shell cat $(1)/version.txt) ./$(1)

.PHONY: buildAll
buildAll: cpp go java node swift web ## Generates the protoc docker containers for all the supported languages

# Version + arches for the S3 protoc-toolchain tarball (consumed by mise's s3:
# backend). Override on the command line, e.g. `make toolchain VER=1.0.0`.
VER ?= 1.0.0
ARCHES ?= amd64 arm64

.PHONY: toolchain
toolchain: ## Builds + publishes the protoc-toolchain tarball(s) to S3 (VER, ARCHES)
	@for arch in $(ARCHES); do \
		echo "==> toolchain $$arch (v$(VER))"; \
		bash toolchain/publish.sh "$(VER)" "$$arch" || exit 1; \
	done

.PHONY: toolchain-build
toolchain-build: ## Stages the toolchain tree locally without publishing (ARCH=amd64|arm64)
	bash toolchain/build-toolchain.sh "out-$(ARCH)" "$(ARCH)"

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
