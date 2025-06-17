# Variable needed in a `FROM` statement
# They must be declared before the first `FROM` statement.
# -----------------------------------------------------------------------------

ARG BASE_OS=ubuntu
ARG BASE_OS_VERSION=24.04
ARG BASE_IMAGE=${BASE_OS}:${BASE_OS_VERSION}


# Stage 1: image to fetch python requirements
# -----------------------------------------------------------------------------

FROM docker.io/alpine/git as requirements-fetcher

ARG ZEPHYR_VERSION=v3.7
ARG ZEPHYR_BRANCH=${ZEPHYR_VERSION}-branch

WORKDIR /zephyr

# Sparse checkout only the scripts/ directory
RUN git init && \
    git remote add origin https://github.com/zephyrproject-rtos/zephyr.git && \
    git config core.sparseCheckout true && \
    echo "scripts/" >> .git/info/sparse-checkout && \
    git pull --depth 1 origin ${ZEPHYR_BRANCH}


# Stage 2: Final image
# -----------------------------------------------------------------------------

FROM ${BASE_IMAGE}

# Copy only the requirements*.txt files from the sparse checkout
COPY --from=requirements-fetcher zephyr/scripts/requirements*.txt /tmp/requirements/

# Some build time variables
# -----------------------------------------------------------------------------

ARG ZEPHYR_SDK_VERSION=0.16.9
ARG TOOLCHAIN_LIST="-t x86_64-zephyr-elf -t arm-zephyr-eabi"
ARG VIRTUAL_ENV=/opt/venv
ARG TOOLCHAIN_VARIANT=zephyr
ARG TOOLCHAIN_DIR=/opt/toolchains


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
    && python3 -m pip install --no-cache-dir west \
    && python3 -m pip install --no-cache-dir -r /tmp/requirements/requirements.txt


# Set up directories
# -----------------------------------------------------------------------------

RUN mkdir -p ${TOOLCHAIN_DIR}


# Install toolchains (Zephyr SDK)
# -----------------------------------------------------------------------------

# Download SDK
RUN cd ${TOOLCHAIN_DIR} \
    && wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/sha256.sum | shasum --check --ignore-missing \
    && tar xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz \
    && rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz

# Setup toolchains
RUN cd ${TOOLCHAIN_DIR}/zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && bash setup.sh -c ${TOOLCHAIN_LIST}

# Install host tools
RUN cd ${TOOLCHAIN_DIR}/zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/hosttools_linux-x86_64.tar.xz \
    && tar xf hosttools_linux-x86_64.tar.xz \
    && rm hosttools_linux-x86_64.tar.xz \
    && bash zephyr-sdk-x86_64-hosttools-standalone-*.sh -y -d .

ENV ZEPHYR_TOOLCHAIN_VARIANT=${TOOLCHAIN_VARIANT}
ENV ZEPHYR_SDK_INSTALL_DIR=${TOOLCHAIN_DIR}

# Set working directory
# -----------------------------------------------------------------------------

VOLUME ["/workdir"]
WORKDIR /workdir

