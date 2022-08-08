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

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
