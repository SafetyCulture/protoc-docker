#!/bin/bash

set -o errexit

REPOSITORY="ghcr.io/safetyculture"
PLATFORM="linux/amd64,linux/arm64"

VERSION_FILE="$IMAGE/version.txt"

TAG=`cat $VERSION_FILE`
if [ "$RELEASE_TAG" != "true" ]; then
	TAG="$TAG-pre$(date +%Y%m%d%H%M%S)"
fi

# These images are incompatible with arm64
if [ "$IMAGE" == "protoc-java" ] || [ "$IMAGE" == "protoc-swift" ]; then
	PLATFORM="linux/amd64"
fi

IMAGE_NAME="$REPOSITORY/$IMAGE:$TAG"

echo "Building and pushing multi-arch docker container for $IMAGE_NAME"
docker buildx build --platform "$PLATFORM" --push -t "$IMAGE_NAME" ./$IMAGE
