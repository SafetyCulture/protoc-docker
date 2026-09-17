#!/usr/bin/env bash
set -euo pipefail
#
# Build the native protoc toolchain binaries by reusing protoc-docker's
# existing per-plugin Dockerfiles/build.sh as the build factory, then
# stage a relocatable tree to $OUT (default: out).
#
# Layout produced:
#   $OUT/bin/   all toolchain executables (on PATH at install time)
#   $OUT/lib/   bundled musl runtime libs (libprotobuf/absl/etc.) used via
#               DT_RUNPATH=$ORIGIN/../lib on every staged binary
#
# Corrections vs the original plan brief (verified against the images):
#   - There is no `protoc-gen-objc` binary anywhere in the images. buf's
#     `- name: objc` plugin (buf.gen.crux.yaml) resolves to `protoc`
#     itself (protoc --objc_out), like `cpp`/`java`. It therefore ships
#     as the `protoc` binary; nothing extra to copy. Alpine's
#     grpc-plugins ships `grpc_objective_c_plugin`, which is NOT used by
#     APISchema and is not shipped.
#   - /usr/bin/protoc-system is a symlink to /usr/bin/protoc-24.4.0; the
#     real file is copied so the tarball is not full of broken links.
#   - /usr/bin/grpc_cpp_plugin is dynamically linked against Alpine's
#     libprotoc/libabsl; the whole runtime lib set is bundled into lib/
#     and every staged binary gets DT_RUNPATH=$ORIGIN/../lib (musl on
#     Alpine 3.21+ honours $ORIGIN in RUNPATH), so the tree runs on any
#     stock Alpine (e.g. ci/golang) with no env vars and no apk installs.
#   - protoc-gen-swift/protoc-gen-grpc-swift are glibc binaries (glibc 2.27)
#     with PT_INTERP/rpath hard-coded to /plugins by protoc-swift/build.sh.
#     The CI step image is Alpine (musl) with no system glibc loader, so the
#     bundled loader is mandatory. Libs are rewritten to DT_RUNPATH=$ORIGIN
#     (every lib, since RUNPATH is not transitive). PT_INTERP cannot be
#     $ORIGIN-relative and the glibc 2.27 ld.so CLI forwards a spurious
#     argv[1] that protoc-gen-swift rejects, so each bin/ wrapper does a
#     one-time idempotent `ptc-patchelf --set-interpreter` to the resolved
#     bundled loader, then execs the plugin directly for a clean argv.
#     (buf resolves plugins by PATH, so the bin/ wrappers satisfy
#     protoc-gen-swift / protoc-gen-grpc-swift lookups.)
#   - protoc-node produces npm-installed JS plugins (ts-protoc-gen etc.),
#     not ELF binaries; it is excluded and stays npm-delivered.

OUT="${1:-out}"
ARCH="${2:-$(docker version --format '{{.Server.Arch}}')}"
case "$ARCH" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

need() { command -v "$1" >/dev/null || { echo "missing $1" >&2; exit 1; }; }
need docker
need tar

# Docker build context must not be the repo root (the root .dockerignore
# excludes */*), so each per-plugin dir is its own context, as the
# Makefile does.
build_image() { # build_image <tag> <dir>
  echo "==> docker build (linux/${ARCH}) $1 <- $2"
  docker build --platform "linux/${ARCH}" -t "$1" "$2" >/dev/null
}
build_image "ptc-base-${ARCH}"  protoc/
build_image "ptc-cpp-${ARCH}"   protoc-cpp/
build_image "ptc-java-${ARCH}"  protoc-java/
build_image "ptc-web-${ARCH}"   protoc-web/
# swift:5.2 is amd64-only (publish.sh pins protoc-swift to linux/amd64);
# the arm64 toolchain ships without the Swift plugins.
if [ "$ARCH" = "amd64" ]; then
  build_image "ptc-swift-${ARCH}" protoc-swift/
fi

# Patch staged binaries so DT_RUNPATH=$ORIGIN/../lib resolves the bundled
# libs. Requires host `patchelf` if set, else a patchelf container.
PATCH_TAG="ptc-patchelf-${ARCH}"
if command -v patchelf >/dev/null; then
  PATCHARM=(patchelf)
else
  docker build --platform "linux/${ARCH}" -t "$PATCH_TAG" - >/dev/null <<'DOCKER'
FROM alpine:3.21
RUN apk add --no-cache patchelf
DOCKER
  PATCHARM=(docker run --rm --platform "linux/${ARCH}" -v "$(pwd)":/w -w /w "$PATCH_TAG" patchelf)
fi

rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib"

copy() { # copy <image> <container-path> <dest-name>
  local cid
  cid=$(docker create --platform "linux/${ARCH}" "$1")
  # shellcheck disable=SC2064
  trap "docker rm -f '$cid' >/dev/null 2>&1 || true" EXIT
  docker cp "$cid:$2" "$OUT/bin/$3"
  docker rm "$cid" >/dev/null
  trap - EXIT
}
copy_libs() { # copy_libs <image> <container-dir>
  local cid
  cid=$(docker create --platform "linux/${ARCH}" "$1")
  # shellcheck disable=SC2064
  trap "docker rm -f '$cid' >/dev/null 2>&1 || true" EXIT
  docker cp "$cid:$2" "$OUT/lib/.staged-libs"
  docker rm "$cid" >/dev/null
  trap - EXIT
}

# Base: protoc 26.1 (codegen) + protoc-system 24.4 (plugin compile).
# protoc 26.1 is a static binary (no ldd deps); protoc-system is the real
# file behind the /usr/bin/protoc-system symlink.
copy "ptc-base-${ARCH}" /usr/bin/protoc           protoc
copy "ptc-base-${ARCH}" /usr/bin/protoc-24.4.0    protoc-system
copy "ptc-cpp-${ARCH}"  /usr/bin/grpc_cpp_plugin  grpc_cpp_plugin
copy "ptc-cpp-${ARCH}"  /usr/local/bin/protoc-gen-cruxclient protoc-gen-cruxclient
copy "ptc-java-${ARCH}" /usr/local/bin/protoc-gen-grpc-java  protoc-gen-grpc-java
copy "ptc-web-${ARCH}"  /usr/local/bin/protoc-gen-grpc-web protoc-gen-grpc-web

# Runtime libs for the dynamically linked musl binaries above: the union
# of the base image's /usr/lib (protobuf 24 + absl + grpc_plugin_support,
# matching grpc_cpp_plugin and protoc-gen-cruxclient) and the java/web
# images' /usr/lib (protobuf 29 for protoc-gen-grpc-java/-web).
# Base libs are merged LAST so the newest generic libs (libstdc++ 6.0.33
# from Alpine 3.21) win over the java/web images' older Alpine 3.15 ones.
copy_libs "ptc-java-${ARCH}" /usr/lib
rm -rf "$OUT/lib/pb29-libs"; mv "$OUT/lib/.staged-libs" "$OUT/lib/pb29-libs"
copy_libs "ptc-web-${ARCH}"  /usr/lib
rm -rf "$OUT/lib/.staged-libs"
copy_libs "ptc-base-${ARCH}"  /usr/lib
rm -rf "$OUT/lib/base-libs"; mv "$OUT/lib/.staged-libs" "$OUT/lib/base-libs"

# Merge every staged lib dir into lib/ proper (basename collisions keep
# the first copy; the dirs only overlap in generic libs like libz).
for d in pb29-libs web-libs base-libs; do
  [ -d "$OUT/lib/$d" ] || continue
  cp -a "$OUT/lib/$d/." "$OUT/lib/" 2>/dev/null || cp -R "$OUT/lib/$d/." "$OUT/lib/"
  rm -rf "$OUT/lib/$d"
done

# Swift plugins: glibc binaries (swift:5.2, glibc 2.27). The CI step image is
# Alpine (musl), which has no system glibc loader, so the bundled loader in
# lib/swift/plugins is mandatory. Two relocation problems are solved here:
#   1. Libs: protoc-swift/build.sh sets rpath=/plugins on every lib. We
#      rewrite every bundled lib + plugin to DT_RUNPATH=$ORIGIN so the tree
#      resolves from any install prefix. (glibc RUNPATH is not transitive, so
#      EVERY lib must carry $ORIGIN, not just the plugins.)
#   2. Interpreter: PT_INTERP is a hard-coded absolute path the kernel reads
#      at exec time; it cannot be $ORIGIN-relative. We cannot know the final
#      install prefix at stage time, and the glibc 2.27 ld.so CLI forwards its
#      own argv to the program (so `ld.so prog` makes protoc-gen-swift see a
#      spurious argv[1] and exit "Unknown argument"). The only invocation that
#      yields a clean argv is direct kernel exec via a correct PT_INTERP.
#      We therefore ship a `patchelf` in bin/ (rpath=$ORIGIN/../lib so it runs
#      off the bundled musl libs on the Alpine host) and each bin/ wrapper
#      performs a one-time, idempotent `patchelf --set-interpreter` to the
#      resolved bundled loader, then execs the plugin directly.
if [ "$ARCH" = "amd64" ]; then
  mkdir -p "$OUT/lib/swift"
  cid=$(docker create --platform linux/amd64 "ptc-swift-${ARCH}")
  # shellcheck disable=SC2064
  trap "docker rm -f '$cid' >/dev/null 2>&1 || true" EXIT
  docker cp "$cid:/plugins" "$OUT/lib/swift/plugins"
  docker rm "$cid" >/dev/null
  trap - EXIT

  # Ship patchelf (needed once per install to fix PT_INTERP). It is a musl
  # binary; rpath is set to $ORIGIN/../lib below with the other staged bins.
  peid=$(docker create --platform "linux/${ARCH}" "$PATCH_TAG")
  # shellcheck disable=SC2064
  trap "docker rm -f '$peid' >/dev/null 2>&1 || true" EXIT
  docker cp "$peid:/usr/bin/patchelf" "$OUT/bin/ptc-patchelf"
  docker rm "$peid" >/dev/null
  trap - EXIT

  SWDIR="$OUT/lib/swift/plugins"
  # 1. Rewrite every bundled lib + plugin rpath to $ORIGIN (runs at stage time
  #    where patchelf is available). libICU/Foundation/etc. are deps of the
  #    libs, not the plugin, so each needs its own $ORIGIN.
  for f in "$SWDIR"/*.so* "$SWDIR"/protoc-gen-swift "$SWDIR"/protoc-gen-grpc-swift; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in ld-linux*) continue ;; esac
    "${PATCHARM[@]}" --set-rpath '$ORIGIN' "$f" 2>/dev/null || true
  done
  # 2. Seed the plugin PT_INTERP to the staged loader path; wrappers rewrite it
  #    to the resolved absolute install path on first run (idempotent).
  for p in protoc-gen-swift protoc-gen-grpc-swift; do
    "${PATCHARM[@]}" --set-interpreter "$SWDIR/ld-linux-x86-64.so.2" "$SWDIR/$p" 2>/dev/null || true
    cat > "$OUT/bin/$p" <<WRAP
#!/bin/sh
# Relocatable launcher for the glibc Swift plugin. One-time: point PT_INTERP
# at the resolved bundled glibc loader (idempotent), then exec the plugin
# directly so it receives a clean argv (the glibc 2.27 ld.so CLI would inject
# the program path as argv[1] and protoc-gen-swift rejects it).
set -e
dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd -P)
plugins=\$dir/../lib/swift/plugins
loader=\$plugins/ld-linux-x86-64.so.2
prog=\$plugins/$p
cur=\$("\$dir/ptc-patchelf" --print-interpreter "\$prog" 2>/dev/null || true)
if [ "\$cur" != "\$loader" ]; then
  "\$dir/ptc-patchelf" --set-interpreter "\$loader" "\$prog"
fi
exec "\$prog" "\$@"
WRAP
    chmod +x "$OUT/bin/$p"
  done
fi

# Give every staged ELF binary DT_RUNPATH=$ORIGIN/../lib so the bundled
# musl libs resolve from any install prefix without env vars. Statically
# linked binaries (protoc 26.1) have no .dynamic section and are skipped.
echo "==> patching DT_RUNPATH=\$ORIGIN/../lib on staged binaries"
for f in "$OUT"/bin/*; do
  [ -f "$f" ] || continue
  [ "$(head -c 4 "$f")" = $'\x7fELF' ] || continue
  # shellcheck disable=SC2312
  if "${PATCHARM[@]}" --print-rpath "$f" >/dev/null 2>&1; then
    "${PATCHARM[@]}" --set-rpath '$ORIGIN/../lib' "$f" >/dev/null
  fi
done

# --- failing-check-first assertions: every expected binary must exist ---
fail=0
for b in protoc protoc-system grpc_cpp_plugin protoc-gen-cruxclient \
         protoc-gen-grpc-java protoc-gen-grpc-web; do
  [ -f "$OUT/bin/$b" ] || { echo "MISSING: $OUT/bin/$b" >&2; fail=1; }
done
if [ "$ARCH" = "amd64" ]; then
  for b in protoc-gen-swift protoc-gen-grpc-swift; do
    [ -f "$OUT/bin/$b" ] || { echo "MISSING: $OUT/bin/$b" >&2; fail=1; }
  done
fi
if [ "$fail" -ne 0 ]; then
  echo "toolchain staging FAILED for linux/${ARCH}" >&2
  exit 1
fi

echo "staged (linux/${ARCH}):"
ls -1 "$OUT/bin"
