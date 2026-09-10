#!/usr/bin/env bash
# Build ARMSX3 inside Docker on a machine with no Android SDK.
#
#   android/docker/run.sh            # a15 (default), APK lands in dist/
#   android/docker/run.sh a13 a15    # any build-variants.sh arguments
#
# Build directories (build-a15/ ...) live in the repo bind mount, so ninja's
# incremental state survives between runs — the cold core build takes 1-2 h,
# a warm one minutes. Gradle caches persist in the armsx3-gradle volume.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# UID/GID of the invoking user, so the bind-mounted output is theirs.
docker build -t armsx3-build \
	--build-arg UID="$(id -u)" --build-arg GID="$(id -g)" \
	"$ROOT/android/docker"

exec docker run --rm --init \
	-v "$ROOT:/repo" \
	-v armsx3-gradle:/home/builder/.gradle \
	armsx3-build /repo/android/docker/build.sh "$@"
