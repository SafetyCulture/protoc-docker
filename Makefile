.PHONY: default
default: help

.PHONY: cpp
cpp: ## Builds the protoc docker container for `cpp`
	$(call build,$(CPP_DIR))

.PHONY: go
go: ## Builds the protoc docker container for `go`
	$(call build,go)

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
build = echo "Building Docker container $(1)"; docker build -t $(REGISTRY)/$(BASE_IMAGE)-$(1):$(shell cat $(1)/version.txt) ./$(1)

.PHONY: buildAll
buildAll: cpp go java node swift web ## Generates the protoc docker containers for all the supported languages

.PHONY: protoc
PROTOC_TAG=$(shell cat version.txt)
protoc: ## Builds the protoc docker container
	echo "Building Docker container $(1)"
	docker build -t $(REGISTRY)/$(BASE_IMAGE):$(PROTOC_TAG) .

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
