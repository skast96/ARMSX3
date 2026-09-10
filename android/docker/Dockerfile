# Build environment for ARMSX3 on Linux: JDK 17 + the exact SDK pieces
# configure.sh demands (NDK 29 line, CMake 3.30.5 — see configure.sh for why
# NDK 28 cannot compile this tree). The repo is bind-mounted at /repo by
# run.sh; nothing project-specific is baked in here.
#
# UID/GID default to 1000 and are overridden by run.sh with the invoking
# user's ids, so everything written to the bind mount (build dirs, jniLibs,
# dist/, .git) belongs to the local user, not root.
FROM debian:bookworm-slim

ARG UID=1000
ARG GID=1000

# python3/make/pkg-config: host tools the LLVM and 3rdparty CMake builds call.
# g++: LLVM's cross-compile configures a NATIVE sub-build (llvm-tblgen runs on
# the build host), which needs a host C/C++ toolchain the NDK does not provide.
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless git curl unzip ca-certificates \
        python3 make pkg-config g++ \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

RUN groupadd -g ${GID} builder && useradd -m -u ${UID} -g ${GID} builder \
    && mkdir -p ${ANDROID_HOME} && chown ${UID}:${GID} ${ANDROID_HOME} \
    # Pre-create the Gradle cache mountpoint: a named volume whose path does
    # not exist in the image is created root-owned, and Gradle then cannot
    # write to it.
    && mkdir -p /home/builder/.gradle && chown ${UID}:${GID} /home/builder/.gradle

USER builder

RUN curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
        -o /tmp/cmdline-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Both build-tools: AGP picks its own default independent of compileSdk, and a
# missing one would otherwise be auto-downloaded into the throwaway container
# layer on every single run.
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null \
    && ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-37.0" \
        "build-tools;35.0.0" \
        "build-tools;36.0.0" \
        "ndk;29.0.14206865" \
        "cmake;3.30.5"

ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

WORKDIR /repo
