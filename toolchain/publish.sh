#!/usr/bin/env bash
set -euo pipefail
#
# Build the protoc toolchain for a given arch and publish the tarball to the
# S3 tools bucket consumed by mise's `s3:` backend.
#
#   toolchain/publish.sh <VER> <amd64|arm64>
#
# Produces:
#   s3://<BUCKET>/release/protoc-toolchain/v<VER>/protoc-toolchain_<VER>_linux_<arch>.tar.gz
# containing bin/ + lib/ (mise extracts and puts bin/ on PATH).
#
# Requires: docker, tar, aws CLI authenticated with an identity allowed to
# write the tools bucket. Run once per arch (the script is arch-specific).
VER="${1:?version e.g. 1.0.0}"
ARCH="${2:?amd64|arm64}"
case "$ARCH" in
  amd64|arm64) ;;
  *) echo "unsupported arch: $ARCH (want amd64|arm64)" >&2; exit 1 ;;
esac

BUCKET=mitti-bk-tools-production-build-us-east-1
PREFIX="release/protoc-toolchain/v${VER}"
TARBALL="protoc-toolchain_${VER}_linux_${ARCH}.tar.gz"
OUT="out-${ARCH}"

cd "$(dirname "$0")/.."

# Build + stage the relocatable tree (bin/ + lib/) for this arch.
bash toolchain/build-toolchain.sh "$OUT" "$ARCH"

# Tarball the whole staged tree (bin AND lib; the swift plugins and the
# dynamically linked musl binaries resolve their libs from lib/). GNU tar
# flags (sorted entries, fixed mtime/ownership) are used when available for
# reproducible archives; macOS bsdtar and others fall back to a plain,
# dereferenced tar.
if tar --version 2>/dev/null | grep -q "GNU tar"; then
  tar -C "$OUT" --sort=name --owner=0 --group=0 --numeric-owner \
      --mtime='UTC 2020-01-01' --dereference -czf "$TARBALL" bin lib
else
  tar -C "$OUT" --dereference -czf "$TARBALL" bin lib
fi
echo "built $TARBALL ($(du -h "$TARBALL" | cut -f1))"

aws s3 cp "$TARBALL" "s3://${BUCKET}/${PREFIX}/${TARBALL}" --acl bucket-owner-full-control
echo "published s3://${BUCKET}/${PREFIX}/${TARBALL}"
