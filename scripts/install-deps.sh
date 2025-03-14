#!/bin/bash
set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo "Cannot detect operating system"
    exit 1
fi

# Install dependencies based on the OS
case "$OS" in
    "Ubuntu" | "Debian GNU/Linux")
        echo "Installing dependencies for $OS..."
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            gcc-aarch64-linux-gnu \
            g++-aarch64-linux-gnu \
            bison \
            flex \
            libssl-dev \
            libelf-dev \
            bc \
            qemu-user-static \
            debootstrap \
            qemu-system-arm \
            u-boot-tools \
            device-tree-compiler \
            libncurses-dev \
            xz-utils \
            cpio \
            rsync \
            wget \
            git \
            python3 \
            python3-dev \
            python3-pip \
            parted \
            dosfstools \
            kpartx \
            e2fsprogs \
            libx11-dev \
            libxft-dev \
            libxext-dev \
            libssl-dev \
            libffi-dev \
            libbz2-dev \
            libreadline-dev \
            libsqlite3-dev \
            liblzma-dev \
            libncursesw5-dev \
            tk-dev
        ;;
    "Fedora" | "CentOS Linux" | "Red Hat Enterprise Linux")
        echo "Installing dependencies for $OS..."
        sudo dnf install -y \
            @development-tools \
            gcc-aarch64-linux-gnu \
            gcc-c++-aarch64-linux-gnu \
            bison \
            flex \
            openssl-devel \
            elfutils-libelf-devel \
            bc \
            qemu-user-static \
            qemu-system-arm \
            uboot-tools \
            dtc \
            ncurses-devel \
            xz \
            cpio \
            rsync \
            wget \
            git \
            python3 \
            python3-devel \
            python3-pip \
            parted \
            dosfstools \
            kpartx \
            e2fsprogs \
            libX11-devel \
            libXft-devel \
            libXext-devel \
            openssl-devel \
            libffi-devel \
            bzip2-devel \
            readline-devel \
            sqlite-devel \
            xz-devel \
            ncurses-devel \
            tk-devel
        ;;
    "Arch Linux")
        echo "Installing dependencies for $OS..."
        sudo pacman -Syu --noconfirm \
            base-devel \
            aarch64-linux-gnu-gcc \
            aarch64-linux-gnu-binutils \
            bison \
            flex \
            openssl \
            elfutils \
            bc \
            qemu \
            qemu-arch-extra \
            uboot-tools \
            dtc \
            ncurses \
            xz \
            cpio \
            rsync \
            wget \
            git \
            python \
            python-pip \
            parted \
            dosfstools \
            kpartx \
            e2fsprogs \
            libx11 \
            libxft \
            libxext \
            openssl \
            libffi \
            bzip2 \
            readline \
            sqlite \
            xz \
            tk
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install the required dependencies manually:"
        echo "- Cross-compiler toolchain for aarch64"
        echo "- Build tools (make, gcc, etc.)"
        echo "- Development libraries for Python"
        echo "- QEMU for testing ARM binaries"
        echo "- Utilities for creating disk images"
        exit 1
        ;;
esac

echo "All dependencies installed successfully!" 