# Zephyr SDK Container

This repository provides a containerized version of the [Zephyr SDK] which
contains the toolchains and tools necessary for building Zephyr applications.


## Overview

The container image includes:

- Zephyr SDK v0.16.9
- Toolchains for x86_64-zephyr-elf and arm-zephyr-eabi architectures
- Host tools for cross-compilation
- Python virtual environment with Zephyr dependencies
- West tool (Zephyr's meta-tool)
- Build tools (CMake, Ninja, etc.)

The container is based on Ubuntu 24.04 and provides a ready-to-use development
environment for Zephyr RTOS without having to install toolchains and
dependencies directly on your host system.


## Versions

The container is based on Ubuntu 24.04. Ubuntu was chosen, because [Zephyrs SDK
installation] guide uses this Linux distro. Version 24.04 is used as this is
the latest LTS version of Ubuntu.

As the container was created for a project that uses Zephyr 3.7.0 (LTS3), the
required Pyhton packages were taken from the `requirments*.txt` files in the
corresponding branch of Zephyrs source repository.

SDK version 0.1.16.9 was chosen, because that is the newest version that is
compatible with Zephyr 3.7.0 (see [Zephyr-SDK Version Compatibility Matrix]).

The specific toolchains `x86_64-zephyr-elf` and `arm-zephyr-eabi` are
installed, because these were the toolchains needed for the project at hand.

All the mentioned versions (and toolchain selection) can be adjusted when
building the container image (refere to the [Building the
Container](#building-the-container) section).


## Building the Container

As I'm lazy and don't want to remember the build command, I added a make file.
You can build the container simply by running:

```bash
make image
```

By default, the build uses Podman. If you prefer to use Docker, you can
override the image build tool (IBT):

```bash
make IBT=docker image
```

If you want to change any of the mentioned [Versions](#versions), the following
variables can be used:

- BASE_OS
- BASE_OS_VERSION
- ZEPHYR_VERSION
- ZEPHYR_SDK_VERSION
- TOOLCHAIN_LIST

There are multiple options, how you can do that:

- change them directly in the Containerfile
- pass them to the `podman build` or `docker build` command, using the
  `--build-arg` option (if you don't use the Makefile)
- change them in the Makefile
- pass them to the `make` command, just like in the image build tool example
  above

Please have a look into the Containerfile or the Makefile for details.


## Using the Container

The container can be used to build Zephyr applications. To do so, change into
your Zephyr workspace and run (replace `podman` with `docker` in case you built
a docker image):

```bash
podman run --rm -it -v $(pwd):/workdir schuam/zephyr-sdk:sdk-v<SDK_VERSION>_zephyr-<ZEPHYR_VERSION>_<YYYY-MM-DD>
```

Replace:
- `<SDK_VERSION>` with the SDK version you built the container for
- `<ZEPHYR_VERSION>` with the Zephyr version you used for he Python requirment
  files
- `<YYYY-MM-DD>` with the date you build the container

Inside the container you can use you normal `west build (...)` command to build
your application.

**Note**: Inside the container the environment variable
`ZEPHYR_SDK_INSTALL_DIR` and `ZEPHYR_TOOLCHAIN_VARIANT` are already set. You
have to set `ZEPHYR_BASE` yourself. This variable depends on how you set up
your west workspace and how you mount the workspace in the container.


[Zephyr SDK]: https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html
[Zephyr-SDK Version Compatibility Matrix]: https://docs.google.com/spreadsheets/d/1wzGJLRuR6urTgnDFUqKk7pEB8O6vWu6Sxziw_KROxMA/edit?gid=0#gid=0
[Zephyrs SDK installation]: https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html#zephyr-sdk-installation

