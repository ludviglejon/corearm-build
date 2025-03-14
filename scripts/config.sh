#!/bin/bash

# Cross-compilation settings
CROSS_COMPILE="aarch64-linux-gnu-"
ARCH="arm64"

# Target CPU settings 
TARGET_CPU="cortex-a53"
CPU_FREQ="1.5GHz"  # Typical frequency for Cortex-A53
CPU_CORES="4"

# Build versions
KERNEL_VERSION="5.15"
BUSYBOX_VERSION="1.34.1"
PYTHON_VERSION="3.9.7"

# System settings
HOSTNAME="boundless"
USERNAME="user" 