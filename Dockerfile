FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    ca-certificates \
    gnupg \
    wget \
    git \
    build-essential \
    ninja-build \
    pkg-config \
    binutils \
    python3 \
    zip \
    unzip \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libegl1-mesa-dev \
    libdrm-dev \
    libx11-dev \
    libxext-dev \
    libxrandr-dev \
    libxfixes-dev \
    libxi-dev \
    libxcursor-dev \
    libxinerama-dev \
    libwayland-dev \
    wayland-protocols \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Latest CMake from Kitware
# ------------------------------------------------------------
RUN wget -O /tmp/kitware-key.asc \
        https://apt.kitware.com/keys/kitware-archive-latest.asc \
    && gpg --dearmor \
        < /tmp/kitware-key.asc \
        > /usr/share/keyrings/kitware-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main" \
        > /etc/apt/sources.list.d/kitware.list \
    && apt-get update \
    && apt-get install -y kitware-archive-keyring cmake \
    && rm -rf /var/lib/apt/lists/* /tmp/kitware-key.asc

# ------------------------------------------------------------
# Build SDL2 statically
# ------------------------------------------------------------
WORKDIR /tmp

RUN git clone \
        --depth 1 \
        --branch release-2.30.9 \
        https://github.com/libsdl-org/SDL.git SDL2 \
    && cmake \
        -S SDL2 \
        -B SDL2/build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/SDL2 \
        -DBUILD_SHARED_LIBS=OFF \
        -DSDL_SHARED=OFF \
        -DSDL_STATIC=ON \
        -DSDL_TESTS=OFF \
        -DSDL_EXAMPLES=OFF \
        -DSDL_OPENGL=ON \
        -DSDL_OPENGLES=ON \
        -DSDL_VULKAN=OFF \
    && cmake --build SDL2/build --parallel \
    && cmake --install SDL2/build \
    && rm -rf SDL2

ENV CMAKE_PREFIX_PATH=/opt/SDL2
ENV PKG_CONFIG_PATH=/opt/SDL2/lib/pkgconfig

# ------------------------------------------------------------
# Clone Shipwright - leveled-blair
# ------------------------------------------------------------
WORKDIR /opt

RUN git clone \
        --branch leveled-blair \
        --single-branch \
        https://github.com/Arrenton/Shipwright.git Shipwright \
    && cd Shipwright \
    && git submodule update --init --recursive

WORKDIR /opt/Shipwright

# ------------------------------------------------------------
# Configure Shipwright
# ------------------------------------------------------------
RUN cmake \
    -S . \
    -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_OPENGLES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.so" \
    -DCMAKE_PREFIX_PATH=/opt/SDL2 \
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON

# ------------------------------------------------------------
# Build SoH
# ------------------------------------------------------------
RUN cmake \
    --build build \
    --config Release \
    --parallel

# ------------------------------------------------------------
# Generate soh.o2r
# ------------------------------------------------------------
RUN cmake \
    --build build \
    --target GenerateSohOtr \
    --config Release \
    --parallel

# ------------------------------------------------------------
# Runtime output
#
# /output is supplied by the WSL2 bind mount.
# Only the final binaries are copied there.
# ------------------------------------------------------------
CMD ["bash", "-c", \
    "mkdir -p /output && \
     find /opt/Shipwright/build -type f \\( -name soh -o -name soh.o2r \\) \
     -exec cp -v {} /output/ \\;"]
