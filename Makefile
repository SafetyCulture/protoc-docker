.PHONY: default
default: help

.PHONY: cpp
cpp: ## Builds the protoc docker container for `cpp`
	$(call build,cpp)

.PHONY: go
go: ## Builds the protoc docker container for `go`
	$(call build,go)

.PHONY: go-multiarch
go-multiarch: ## Builds the protoc docker container for `go` for multi-arch and pushes to registry
	$(call push-multiarch,go)


.PHONY: java
java: ## Builds the protoc docker container for `java`
	$(call build,java)

.PHONY: node
node: ## Builds the protoc docker container for `node`
	$(call build,node)

.PHONY: swift
swift: ## Builds the protoc docker container for `swift`
	$(call build,swift)

.PHONY: web
web: ## Builds the protoc docker container for `web`
	$(call build,web)

REGISTRY=safetyculture
BASE_IMAGE=protoc

.PHONY: build
build = echo "Building Docker container $(1)"; docker build --no-cache -t $(REGISTRY)/$(BASE_IMAGE)-$(1):$(shell cat $(1)/version.txt) ./$(1)

.PHONY: push-multiarch
push-multiarch = echo "Building and pushing multi-arch docker container for $(1)"; docker buildx build --platform linux/amd64,linux/arm64 --push -t $(REGISTRY)/$(BASE_IMAGE)-$(1):$(shell cat $(1)/version.txt) ./$(1)

.PHONY: push
push: ## Push the generated docker image to SC docker repository
	echo "Push the Docker image for $(language)"; docker push $(REGISTRY)/$(BASE_IMAGE)-$(language):$(shell cat $(language)/version.txt)

.PHONY: buildAll
buildAll: cpp go java node swift web ## Generates the protoc docker containers for all the supported languages

.PHONY: protoc
PROTOC_TAG=$(shell cat version.txt)
protoc: ## Builds the protoc docker container and pushes to the registry
	echo "Building Docker container $(1)"
	docker buildx build --platform linux/arm64,linux/amd64 --push -t $(REGISTRY)/$(BASE_IMAGE):$(PROTOC_TAG) .

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
