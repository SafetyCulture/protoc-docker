## EX-3143: Protoc and Protoc-cpp Image Upgrades — Progress Notes

### Goal

Upgrade the base `protoc` and `protoc-cpp` Docker images to Alpine 3.21 with updated dependencies, and validate they work with the crux build.

---

### Changes Made (protoc-docker repo)

**Branch:** `EX-3143-protoc-cpp-updates`
**PR:** https://github.com/SafetyCulture/protoc-docker/pull/186 (draft)

#### protoc (1.14.2 → 1.15.0)
- Alpine 3.15 → 3.21
- buf 1.8.0 → 1.66.0
- Explicit community repo for protoc/grpc packages
- Added `grpc-plugins` package (in Alpine 3.21, `grpc_cpp_plugin` and other language plugins were split out of the `grpc` package into a separate `grpc-plugins` package)

#### protoc-cpp (1.12.4 → 1.13.0)
- Base image updated to `protoc:1.15.0`
- s12-proto (crux client) 1.36.0 → 1.38.0
- Added `abseil-cpp-dev` and `pkgconf` build dependencies (required for linking against protobuf v24+ on Alpine 3.21)
- Added build step to regenerate `wire_options.pb.cc/h` at build time (ensures compatibility with whatever protobuf version is in the base image)
- Added `sed` patch to declare `FEATURE_PROTO3_OPTIONAL` support in `protoc-gen-cruxclient` (temporary — see upstream fix below)

#### protoc-go (3.25.6 → 3.26.0)
- Go 1.23.0 → 1.24.0

#### publish.sh
- Temporarily bypasses the `-pre` tag suffix for `protoc` and `protoc-cpp` images on non-main branches, so CI can publish release tags for testing. **This should be reverted before merging to main.**

#### protoc (1.15.0 — revised)
- Now installs protoc 26.1 from official GitHub release instead of Alpine's protoc 24.4
- Alpine's protoc (24.4) kept as `/usr/bin/protoc-system` for plugin compilation
- Protoc 26.1 installed as `/usr/bin/protoc` for code generation (matches crux's bundled protobuf v26.1)
- Multi-arch support via `TARGETARCH` build arg (aarch_64 / x86_64)

#### protoc-cpp (1.13.0 — revised)
- `build.sh` uses `protoc-system` (Alpine's 24.4) to regenerate `wire_options.pb.cc/h` during plugin build (must match `protobuf-dev` headers)
- Runtime code generation uses protoc 26.1 (inherited from base image)

---

### Issues Found and Fixed

#### 1. CI: Dependent images fail on PR branches

**Problem:** The CI workflow uses `max-parallel: 1` to build images sequentially, but on non-main branches, `publish.sh` appends a `-pre` timestamp suffix to the tag. The base `protoc` image is published as e.g. `1.15.0-pre20260328...`, but `protoc-cpp`'s Dockerfile hardcodes `FROM protoc:1.15.0`. So downstream images can't find the base image on PR branches.

**Why it wasn't caught before:** Previous PRs (e.g. #181) only bumped downstream image references to an already-published base version. This is the first PR to bump the base protoc version AND downstream images simultaneously.

**Workaround:** Modified `publish.sh` to skip the `-pre` suffix for `protoc` and `protoc-cpp`. This is temporary and should be reverted before merge.

**Proper fix (future):** Either split base image bumps into a separate PR that merges first, or update the CI to pass the actual published tag to dependent builds.

#### 2. Missing `grpc_cpp_plugin` in Alpine 3.21

**Problem:** After upgrading to Alpine 3.21, `grpc_cpp_plugin` was missing from the protoc image, causing: `stat /usr/bin/grpc_cpp_plugin: no such file or directory`

**Root cause:** In Alpine 3.21, the gRPC language plugins (`grpc_cpp_plugin`, `grpc_csharp_plugin`, etc.) were moved from the `grpc` package into a separate `grpc-plugins` package.

**Fix:** Added `grpc-plugins` to the `apk add` line in `protoc/Dockerfile`.

#### 3. `protoc-gen-cruxclient` missing proto3 optional support

**Problem:** buf emits a warning/error for 28+ proto files: `plugin "cruxclient" does not support required features. Feature "proto3 optional" is required`.

**Root cause:** The `protoc-gen-cruxclient` plugin in s12-proto doesn't override `GetSupportedFeatures()` to declare `FEATURE_PROTO3_OPTIONAL` support.

**Temporary fix:** Added a `sed` patch in `protoc-cpp/build.sh` that injects the override during the Docker build.

**Upstream fix:** Opened PR on s12-proto: https://github.com/SafetyCulture/s12-proto/pull/155. Once merged and a new version is tagged, the `sed` patch can be removed from `build.sh` and `CRUX_CLIENT_RELEASE` bumped.

#### 4. `grpc-java` plugin also missing proto3 optional support

**Problem:** Same warning as above but for `grpc-java` plugin.

**Root cause:** `protoc-java` image uses `grpc-java 1.27.0` (from 2020). Proto3 optional support was added in grpc-java 1.38+.

**Status:** Not in scope for this PR. Should be tracked separately.

#### 5. Crux CMake build fails — abseil export targets missing

**Problem:** Building crux fails with many CMake errors like: `install(EXPORT "protobuf-targets") includes target "libprotobuf-lite" which requires target "absl_absl_check" that is not in any export set.`

**Root cause:** Crux's `CMakeLists.txt` adds grpc as a subdirectory without setting `ABSL_ENABLE_INSTALL`. The bundled protobuf (v3.26.1 / protobuf v26) depends on abseil and tries to export targets that reference abseil, but abseil's install/export targets are disabled by default when built as a subdirectory (they're only enabled when `gRPC_INSTALL` is `ON`, which it isn't).

**Fix:** Added `set(ABSL_ENABLE_INSTALL ON CACHE BOOL "Enable abseil install targets" FORCE)` before `add_subdirectory(grpc)` in `crux/CMakeLists.txt`. This registers abseil's export targets so protobuf's `install(EXPORT)` can find them.

**Versions involved:**
- grpc: v1.30.0-derived (commit b8d48df729)
- protobuf: v3.26.1 (bundled in grpc third_party)
- abseil-cpp: 20240116.0 (bundled in grpc third_party)

#### 6. Abseil-cpp CMake flag deduplication on macOS (Apple Silicon)

**Problem:** Building crux locally on macOS fails with: `clang++: error: unsupported option '-msse4.1' for target 'arm64-apple-darwin25.3.0'`

**Root cause:** Abseil-cpp's `AbseilConfigureCopts.cmake` (version 20240116.0, bundled in grpc) generates multi-arch compiler flags using `-Xarch_x86_64` prefix for each flag. CMake deduplicates the repeated `-Xarch_x86_64`, causing `-msse4.1` to leak to the arm64 compiler without its arch-scoping prefix.

- Expected: `-Xarch_x86_64 -maes -Xarch_x86_64 -msse4.1 -Xarch_arm64 -march=armv8-a+crypto`
- Actual: `-Xarch_x86_64 -maes -msse4.1 -Xarch_arm64 -march=armv8-a+crypto`

**Fix:** Applied upstream fix (already in abseil master) using `SHELL:` prefix to keep each `-Xarch/<flag>` pair as an indivisible unit. Patch applied at build time in `crux/run.sh`'s `cmake_configure()` function — only on macOS, only if the unpatched pattern is present (idempotent, self-removing when abseil is upgraded).

**Scope:** macOS-only. On Linux, abseil takes the single-architecture codepath and doesn't use `-Xarch` flags at all.

**Files modified:**
- `crux/run.sh` — added conditional sed patch in `cmake_configure()`
- `crux/deps/crux-lib-deps/deps/grpc/third_party/abseil-cpp/absl/copts/AbseilConfigureCopts.cmake` — patched locally (not committed, applied by run.sh)

#### 7. Protobuf version mismatch — protoc 24.4 vs bundled protobuf 26.1

**Problem:** After regenerating `s12-apis-crux` proto files, crux compilation fails with errors like: `unknown type name 'PROTOBUF_ATTRIBUTE_REINITIALIZES'`, `use of undeclared identifier 'GetOwningArena'`, `use of undeclared identifier 'CreateMaybeMessage'`

**Root cause:** The crux-lib-deps gRPC upgrade (1.42.0 → 1.65.5) brought protobuf from ~v21 to **v26.1** (`GOOGLE_PROTOBUF_VERSION 5026001`). But Alpine 3.21 only packages **protoc 24.4**. The generated `.pb.h` files (from protoc 24.4) use APIs that were changed/removed in protobuf v26.1 headers.

- Generated `.pb.h` files: `PROTOBUF_VERSION 4024004` (protoc 24.4)
- Bundled protobuf headers in `grpc/third_party/protobuf`: v26.1 (`5026001`)
- Alpine 3.21 protoc package: 24.4
- Alpine edge protoc package: 31.1 (too new)
- No Alpine version ships protobuf 26.1

**Fix:** Updated `protoc/Dockerfile` to install protoc 26.1 from the official GitHub release binary instead of using Alpine's package:

- Alpine's protoc (24.4) is kept as `/usr/bin/protoc-system` — needed for compiling plugins against Alpine's `protobuf-dev` headers
- Protoc 26.1 is installed as `/usr/bin/protoc` — used by buf for code generation
- Multi-arch support via Docker's `TARGETARCH` build arg (maps to `aarch_64` / `x86_64` for the GitHub release asset naming)
- `protoc-cpp/build.sh` updated to use `protoc-system` for regenerating `wire_options.pb.cc/h` (must match `protobuf-dev` headers for plugin compilation)

**Key insight:** buf delegates to the system `protoc` binary for built-in plugins like `cpp`. So the protoc version in the Docker image directly determines the generated code version. buf's own Go compiler (protocompile) is not used for C++ code generation.

**Verification:** Prebuilt protoc 26.1 binary from GitHub works on Alpine (musl) despite being glibc-linked (statically linked).

#### 8. BaseAPITest tests take ~5s each — gRPC mock server shutdown delay

**Problem:** Every `BaseAPITest` test takes ~5 seconds after the gRPC 1.42.0 → 1.65.5 upgrade, even trivially passing ones.

**Root cause:** `GRPCMockServerImpl::Stop()` called `mServer->Shutdown()` with no deadline. In gRPC 1.65.5, the no-argument `Shutdown()` waits ~5 seconds for connected clients to disconnect gracefully before force-closing. In 1.42.0 this was near-instant.

**Diagnosis:** Added `std::chrono::high_resolution_clock` timing instrumentation to `BaseAPITest::SetUp()` and `TearDown()` in `test_utils.h`. Output showed `ServerStop=4997ms` consistently, confirming the delay was entirely in `mMockServer->Stop()`.

**Fix:** Changed `mServer->Shutdown()` to `mServer->Shutdown(deadline)` with an immediate deadline (`std::chrono::system_clock::now()`), forcing gRPC to terminate all RPCs and connections immediately. This is appropriate for test mock servers where graceful shutdown is unnecessary.

**File modified:** `crux/src/testing_support/grpc_mock_server.impl.cc`

#### 9. MutationHandlerTests take ~5s each — TCP SYN timeout on firewalled port

**Problem:** All 13 `MutationHandlerTests` that make gRPC calls take ~5 seconds each.

**Root cause:** The test fixture's `GetEngineConfiguration()` used `api.safetyculture.com:433` as the endpoint. Port 433 is firewalled (packets silently dropped), so each TCP SYN times out after ~5 seconds. In gRPC 1.42.0 the connection failure was reported faster; in 1.65.5 the full TCP timeout is hit.

**Fix:** Changed the endpoint to `localhost:1`. Port 1 is not in use and connections get an immediate TCP RST (ECONNREFUSED), so gRPC returns `UNAVAILABLE` instantly. The test assertions remain valid since both firewalled and refused ports yield the same gRPC status.

**File modified:** `crux/src/engine/crux/tests/mutation_handler_tests.cc`

#### 10. AgendaSyncPlugin tests fail — test/implementation mismatch from lost merge

**Problem:** `AgendaSyncTests.CanPerformFullSync` crashes with `discovery_response->change_token().empty()` being true and `add_size()` returning 0.

**Root cause:** Commit `3add83b3e` ([EX-2373] Simplify AgendaSyncPlugin to full-replacement sync) updated both the implementation and tests — `SyncDiscovery` now returns an empty `SyncDiscoveryResponse{}` and caches items directly. However, during the gRPC upgrade rebase/merge, the test file changes were lost while the implementation changes were kept. The tests still expected the old populated response.

**Fix:** Restored the test file from commit `3add83b3e`, then removed two `EXPECT_FALSE(request.has_change_token())` assertions that referenced a field removed in a later API schema update (`a58c6932b` — AgendaItem schema v1.288.22).

**File modified:** `crux/src/domain/home/sync/tests/agenda_sync_plugin_tests.cc`

#### 11. AgendaSyncPlugin DeleteRecords not updated for full-replacement sync

**Problem:** `AgendaSyncTests.DeleteRecordsIsNoOp` fails — test expects `DeleteRecords()` to return an empty set, but the implementation iterates through record IDs, calls `DeleteAgendaItemById()` for each, and returns them as successful deletions.

**Root cause:** Same merge issue as #10. Commit `3add83b3e` simplified AgendaSyncPlugin to full-replacement sync where deletions are handled implicitly when the full item list is replaced during `SyncDiscovery`. The `DeleteRecords` implementation should have been updated to a no-op (like `FetchRecords` was), but the old deletion logic survived the rebase.

**Fix:** Changed `DeleteRecords()` to return `{}` with a comment explaining that full-replacement sync handles deletions implicitly.

**File modified:** `crux/src/domain/home/sync/agenda_sync_plugin.cc`

#### 12. IncidentsAPITests.CanUpdateIncidentOccurredAt — wrong variable in assertion

**Problem:** `IncidentsAPITests.CanUpdateIncidentOccurredAt` fails because `modified_at` fields don't match the expected values.

**Root cause:** Pre-existing test bug. The test creates two separate timestamps (`occurredAt` and `modifiedAt`) via `GetCurrentTime()`, sets them on the request, but the mock server callback only captures `occurredAt` and asserts `modified_at` against it instead of `modifiedAt`. Since the two `GetCurrentTime()` calls can return different nanosecond values, the assertion fails.

**Fix:** Updated the lambda capture to include `modifiedAt` and changed the `modified_at` assertions to compare against `modifiedAt` instead of `occurredAt`.

**File modified:** `crux/src/domain/tasks/incidents/tests/incidents_api_tests.cc`

#### 13. Android build: `ares.h` not found

**Problem:** Android build fails with `fatal error: 'ares.h' file not found` when compiling crux.

**Root cause:** In the newer c-ares version bundled with gRPC 1.65.5, headers were moved from `cares/cares/` to `cares/cares/include/`. The Android cmake files only had the old include path.

**Fix:** Added `${DEPSDIR}/crux-lib-deps/deps/grpc/third_party/cares/cares/include` to `target_include_directories` in both `crux.cmake` and `cruxDebug.cmake`.

**Files modified:** `crux/platforms/android/crux/cmake/crux.cmake`, `crux/platforms/android/crux/cmake/cruxDebug.cmake`

#### 14. Android linker: undefined `utf8_range::IsStructurallyValid`

**Problem:** Android linker error: `undefined symbol: utf8_range::IsStructurallyValid(std::__ndk1::basic_string_view<char, std::__ndk1::char_traits<char>>)` with multiple references from `libprotobuf.a`.

**Root cause:** Protobuf v26+ depends on `utf8_range` as a separate library. Previously it was bundled within protobuf. The prebuilt `libutf8_validity.a` was available in `crux-lib-deps` but not linked.

**Fix:** Added `libutf8_validity` as a `STATIC IMPORTED` library target and linked it to the crux shared library in both `crux.cmake` and `cruxDebug.cmake`.

**Files modified:** `crux/platforms/android/crux/cmake/crux.cmake`, `crux/platforms/android/crux/cmake/cruxDebug.cmake`

#### 15. Android linker: undefined abseil symbols from `libprotobuf.a`

**Problem:** Android linker error: `undefined symbol: absl::lts_20240116::cord_internal::GetEstimatedMemoryUsage(...)` and many other abseil symbols referenced by `libprotobuf.a`.

**Root cause:** Protobuf v26+ depends on abseil-cpp as a separate library (previously symbols were bundled or not needed). The prebuilt abseil `.a` files existed in `crux-lib-deps` (90 libraries) but were not linked.

**Fix:** Added a `file(GLOB ...)` + `foreach` block to dynamically find all `libabsl_*.a` files and link them as `STATIC IMPORTED` targets. This avoids enumerating all 90 libraries individually; the linker only pulls in symbols actually referenced.

**Files modified:** `crux/platforms/android/crux/cmake/crux.cmake`, `crux/platforms/android/crux/cmake/cruxDebug.cmake`

#### 16. Android linker: abseil LTS version mismatch in `libabsl_flags_registry.a`

**Problem:** After linking all abseil libraries, a new linker error appeared: `undefined symbol: absl::lts_2020_02_25::Mutex::Lock()` referenced from `libabsl_flags_registry.a`.

**Root cause:** The prebuilt abseil libraries in `crux-lib-deps` are a mix of two LTS versions:
- 89 libraries: `lts_20240116` (rebuilt with gRPC 1.65.5) — correct
- 1 library: `libabsl_flags_registry.a` still at `lts_2020_02_25` (leftover from gRPC 1.42.0) — stale

The old library references `lts_2020_02_25::Mutex::Lock()` which doesn't exist in the new `lts_20240116` synchronization library (different ABI due to LTS version mangling).

**Fix:** Added `list(FILTER ABSL_LIBS EXCLUDE REGEX "libabsl_flags_registry\\.a$")` to exclude the stale library from the glob. Nothing in protobuf/grpc actually needs the old flags registry.

**Note:** The `crux-lib-deps` prebuilts should eventually be fully rebuilt to eliminate the stale library.

**Files modified:** `crux/platforms/android/crux/cmake/crux.cmake`, `crux/platforms/android/crux/cmake/cruxDebug.cmake`

#### 17. LegacyAPITests.CanListAllMutations — TLS handshake failure

**Problem:** `LegacyAPITests.CanListAllMutations` (and potentially other tests) failed with repeated `SSL_ERROR_SSL: error:1000007d:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED` errors.

**Root cause:** Leftover diagnostic changes from the BaseAPITest timing investigation (issue #8). The mock server had been switched to `InsecureServerCredentials` and `test_utils.h` had `insecure_connection: true`. The `BaseAPITest` fixture used by most tests worked because it matched (insecure client ↔ insecure server). But `LegacyAPITests` has its own fixture with `insecure_connection: false`, so its TLS client tried to handshake with the plaintext mock server.

**Fix:** Reverted both diagnostic changes:
- `grpc_mock_server.impl.cc`: Restored `SslServerCredentials` with cert/key (kept the shutdown deadline fix from issue #8)
- `test_utils.h`: Reverted `insecure_connection` back to `false`

**Files modified:** `crux/src/testing_support/grpc_mock_server.impl.cc`, `crux/src/test_utils/test_utils.h`

#### Ruled out during investigation

- **TLS/certificate SANs:** Generated new CA + server cert with SAN=DNS:localhost,IP:127.0.0.1. No effect on BaseAPITest timing. Then switched to `InsecureServerCredentials` — still 5s. TLS definitively ruled out.
- **IPv4/IPv6 DNS resolution:** Tested with `127.0.0.1` directly — no effect.
- **gRPC deadline as root cause:** Reducing `default_gRPC_timeout` to 1s made tests take 6.5s (longer), confirming the timeout wasn't the direct bottleneck.

---

### Local Testing State

- `ghcr.io/safetyculture/protoc:1.15.0` — built locally, protoc 26.1 + Alpine's protoc 24.4 as protoc-system
- `ghcr.io/safetyculture/protoc-cpp:1.13.0` — built locally with proto3 optional patch, uses protoc-system for plugin build
- Crux CMakeLists.txt patched with `ABSL_ENABLE_INSTALL ON`
- Crux run.sh patched with abseil macOS build fix
- s12-apis-crux regenerated with protoc 26.1 image
- Crux desktop build: passing (all tests green)
- Crux Android cmake: updated with c-ares include path, utf8_validity, abseil libs, flags_registry exclusion
- Crux rebased onto master (1944f8c94), conflicts resolved

---

### TODO Before Merging

- [x] Regenerate s12-apis-crux via `cd crux/deps/APISchema && make crux` with new protoc-cpp:1.13.0
- [x] Verify crux builds successfully end-to-end (cmake configure + build)
- [x] Fix Android cmake: c-ares include path, utf8_validity linking, abseil linking, flags_registry exclusion
- [x] Fix test failures: AgendaSyncPlugin, IncidentsAPITests, mock server TLS, MutationHandlerTests endpoint
- [x] Rebase crux branch onto master and resolve conflicts
- [ ] Revert the `publish.sh` bypass (remove protoc/protoc-cpp from the `-pre` skip list)
- [ ] Once s12-proto PR #155 is merged and tagged, remove the `sed` patch from `protoc-cpp/build.sh` and bump `CRUX_CLIENT_RELEASE`
- [ ] Consider bumping `protoc-java` grpc-java version separately (for proto3 optional support)
- [ ] Commit the crux `CMakeLists.txt` fix (`ABSL_ENABLE_INSTALL ON`) on the appropriate branch
- [ ] Commit the crux `run.sh` abseil macOS patch on the appropriate branch
- [ ] Commit the crux Android cmake changes (c-ares, utf8_validity, abseil) on the appropriate branch
- [ ] Rebuild `crux-lib-deps` Android prebuilts to fix stale `libabsl_flags_registry.a` (lts_2020_02_25)
