#!/bin/bash

set -e

REPOSITORY="ghcr.io/safetyculture"

VERSION_FILE="$IMAGE/version.txt"

TAG=`cat $VERSION_FILE`
if [ "$RELEASE_TAG" != "true" ]; then
	TAG="$TAG-pre$(date +%Y%m%d%H%M%S)"
fi

IMAGE_NAME="$REPOSITORY/$IMAGE:$TAG"

echo "Building and pushing multi-arch docker container for $IMAGE_NAME"
docker buildx build --platform linux/amd64,linux/arm64 --push -t "$IMAGE_NAME" ./$IMAGE
