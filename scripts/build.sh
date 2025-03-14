#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$BUILD_DIR/output"
CONFIGS_DIR="$PROJECT_ROOT/configs"
ROOTFS_TEMPLATE="$PROJECT_ROOT/rootfs"
CORES=$(nproc)

source "$SCRIPT_DIR/config.sh"

# Print banner
echo "====================================="
echo "    Building CoreARM Linux"
echo "    Target: 64-bit ARM Architecture"
echo "====================================="

# Create necessary directories
mkdir -p "$BUILD_DIR/kernel"
mkdir -p "$BUILD_DIR/busybox"
mkdir -p "$BUILD_DIR/rootfs"
mkdir -p "$OUTPUT_DIR"

# Step 1: Download and build the Linux kernel
echo "[1/5] Building Linux kernel..."
if [ ! -d "$BUILD_DIR/kernel/linux" ]; then
    echo "Downloading Linux kernel..."
    cd "$BUILD_DIR/kernel"
    git clone --depth=1 --branch=v5.15 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
fi

cd "$BUILD_DIR/kernel/linux"
cp "$CONFIGS_DIR/kernel/kernel_config" .config
make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE -j$CORES

# Step 2: Build BusyBox
echo "[2/5] Building BusyBox..."
if [ ! -d "$BUILD_DIR/busybox/busybox" ]; then
    echo "Downloading BusyBox..."
    cd "$BUILD_DIR/busybox"
    git clone --depth=1 --branch=1.34.1 https://git.busybox.net/busybox
fi

cd "$BUILD_DIR/busybox/busybox"
cp "$CONFIGS_DIR/system/busybox_config" .config
make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE -j$CORES
make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX="$BUILD_DIR/rootfs" install

# Step 3: Set up root filesystem
echo "[3/5] Setting up root filesystem..."
cp -a "$ROOTFS_TEMPLATE"/* "$BUILD_DIR/rootfs/"

# Create necessary device nodes
mkdir -p "$BUILD_DIR/rootfs/dev"
sudo mknod -m 666 "$BUILD_DIR/rootfs/dev/null" c 1 3
sudo mknod -m 666 "$BUILD_DIR/rootfs/dev/console" c 5 1
sudo mknod -m 666 "$BUILD_DIR/rootfs/dev/tty" c 5 0

# Step 4: Install Python and dependencies
echo "[4/5] Installing Python and dependencies..."
"$SCRIPT_DIR/setup_python.sh" "$BUILD_DIR/rootfs"

# Step 5: Create final image
echo "[5/5] Creating final image..."
cd "$BUILD_DIR"
"$SCRIPT_DIR/create_image.sh" "$BUILD_DIR/rootfs" "$BUILD_DIR/kernel/linux/arch/arm64/boot/Image" "$OUTPUT_DIR/corearm-build.img"

echo "Build completed! Output image: $OUTPUT_DIR/corearm-build.img" 