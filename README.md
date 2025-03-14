# CoreARM Build

A minimalistic Linux build system for 64-bit ARM processors.

## Features
- Command-line only interface
- Optimized for 64-bit 1.5 GHz quad-core ARM Cortex-A53
- Automatic startup of Python applications
- Support for Python GUI applications
- Minimal footprint

## Directory Structure
- `build/` - Build artifacts and compiled system
- `configs/` - Configuration files for kernel, bootloader, etc.
- `scripts/` - Build and utility scripts
- `rootfs/` - Root filesystem template
- `src/` - Source files for custom components

## Building
To build CoreARM:

```bash
./scripts/build.sh
```

This will create a bootable image in the `build/output` directory.

## Requirements
- Linux build environment
- Cross-compilation toolchain for AArch64
- Various build dependencies (see `scripts/install-deps.sh`) 