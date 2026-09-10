#!/usr/bin/env bash
# Runs INSIDE the container (run.sh mounts the repo at /repo). Fetches the
# sources the build needs if this checkout does not have them yet, then hands
# off to the real release script — the container adds an environment, not a
# second build system.
set -euo pipefail
cd /repo

# The checkout's origin may be SSH, and .gitmodules uses relative URLs that
# inherit its scheme -- but the container has no ssh client or keys. Rewrite
# to anonymous HTTPS (writes the ephemeral container user's ~/.gitconfig,
# never the repo's).
git config --global url."https://github.com/".insteadOf "git@github.com:"

# One-time on a fresh checkout; a populated tree makes all three no-ops.
# librashader and libadrenotools are deliberately not submodules (see README).
git submodule update --init --recursive
[ -e 3rdparty/librashader/.git ] || \
	git clone https://github.com/SnowflakePowered/librashader 3rdparty/librashader
[ -e android/armsx3-ui/app/src/main/cpp/libadrenotools/.git ] || \
	git clone --recursive https://github.com/bylaws/libadrenotools \
		android/armsx3-ui/app/src/main/cpp/libadrenotools

# The project's gradle.properties caps the daemon at ~4 GB, which this
# container's release build blows through ("Java heap space"). Properties in
# GRADLE_USER_HOME override the project's, so raise it here -- container only,
# the repo's file stays as the Mac has it tuned.
mkdir -p "$HOME/.gradle"
printf 'org.gradle.jvmargs=-Xmx12g -Dfile.encoding=UTF-8\n' > "$HOME/.gradle/gradle.properties"

mkdir -p dist
OUT_DIR=/repo/dist exec android/build-variants.sh "${@:-a15}"
