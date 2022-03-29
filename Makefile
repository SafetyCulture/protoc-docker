.PHONY: default
default: help

.PHONY: protoc
protoc: ## Builds the protoc docker container and pushes to the registry
	$(call push-multiarch,protoc)

.PHONY: cpp
cpp: ## Builds the protoc docker container for `cpp`
	$(call push-multiarch,protoc-cpp)

.PHONY: go
go: ## Builds the protoc docker container for `go`
	$(call push-multiarch,protoc-go)

.PHONY: java
java: ## Builds the protoc docker container for `java`
	$(call push-multiarch,protoc-java)

.PHONY: node
node: ## Builds the protoc docker container for `node`
	$(call push-multiarch,protoc-node)

.PHONY: swift
swift: ## Builds the protoc docker container for `swift`
	$(call push-multiarch,protoc-swift)

.PHONY: web
web: ## Builds the protoc docker container for `web`
	$(call push-multiarch,protoc-web)

REGISTRY=safetyculture

.PHONY: push-multiarch
push-multiarch = echo "Building and pushing multi-arch docker container for $(1)"; docker buildx build --platform linux/amd64,linux/arm64 --push -t $(REGISTRY)/$(1):$(shell cat $(1)/version.txt) ./$(1)

.PHONY: buildAll
buildAll: cpp go java node swift web ## Generates the protoc docker containers for all the supported languages

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
