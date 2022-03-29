#!/bin/bash

set -e

docker buildx create --use

REPOSITORY="ghcr.io/safetyculture"
BASE_IMAGE="protoc"

VERSION_FILE="./version.txt"
IMAGE_NAME="$REPOSITORY/$BASE_IMAGE"
if [ ! -z "$IMAGE" ]; then
  VERSION_FILE="$IMAGE/version.txt"
  IMAGE_NAME="$IMAGE_NAME-$IMAGE"
fi

TAG=`cat $VERSION_FILE`
if [ "$RELEASE_TAG" != "true" ]; then
	TAG="$TAG-pre$(date +%Y%m%d%H%M%S)"
fi

echo "Building and pushing multi-arch docker container for $IMAGE_NAME:$TAG"
docker buildx build --platform linux/amd64,linux/arm64 --push -t "$IMAGE_NAME":$TAG ./$IMAGE
