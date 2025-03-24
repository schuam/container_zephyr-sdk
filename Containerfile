# Base image
# -----------------------------------------------------------------------------

ARG BASE_OS=ubuntu
ARG BASE_OS_VERSION=24.04
ARG BASE_IMAGE=${BASE_OS}:${BASE_OS_VERSION}

FROM ${BASE_IMAGE}

# Some build time variables
# -----------------------------------------------------------------------------

ARG ZEPHYR_SDK_VERSION=0.17.0
ARG TOOLCHAIN_LIST="-t x86_64-zephyr-elf -t arm-zephyr-eabi"
ARG VIRTUAL_ENV=/opt/venv

# Install required dependencies
# -----------------------------------------------------------------------------

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ccache \
        cmake \
        device-tree-compiler \
        dfu-util \
        file \
        g++-multilib \
        gcc \
        gcc-multilib \
        git \
        gperf \
        libmagic1 \
        libsdl2-dev \
        make \
        ninja-build \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-tk \
        python3-venv \
        python3-wheel \
        wget \
        xz-utils \
    && apt-get clean -y \
    && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/*


# Create virtual environment for python
# -----------------------------------------------------------------------------

ENV VIRTUAL_ENV=${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"
RUN python3 -m venv ${VIRTUAL_ENV} \
    && python3 -m pip install --no-cache-dir west


# Set up directories
# -----------------------------------------------------------------------------

RUN mkdir -p /workspace/ \
    && mkdir -p /opt/toolchains


# Install toolchains (Zephyr SDK)
# -----------------------------------------------------------------------------

# Download SDK
RUN cd /opt/toolchains \
    && wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.0/sha256.sum | shasum --check --ignore-missing \
    && tar xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz

# Setup toolchains
RUN cd /opt/toolchains/zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && bash setup.sh -c ${TOOLCHAIN_LIST}

# Install host tools
RUN cd /opt/toolchains/zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/hosttools_linux-x86_64.tar.xz \
    && tar xf hosttools_linux-x86_64.tar.xz \
    && rm hosttools_linux-x86_64.tar.xz \
    && bash zephyr-sdk-x86_64-hosttools-standalone-*.sh -y -d .


# Set working directory
# -----------------------------------------------------------------------------

WORKDIR /workspace

