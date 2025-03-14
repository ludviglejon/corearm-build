#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/config.sh"

ROOTFS_DIR="$1"
KERNEL_IMAGE="$2"
OUTPUT_IMAGE="$3"

if [ -z "$ROOTFS_DIR" ] || [ -z "$KERNEL_IMAGE" ] || [ -z "$OUTPUT_IMAGE" ]; then
    echo "Usage: $0 <rootfs_dir> <kernel_image> <output_image>"
    exit 1
fi

BUILD_DIR="$PROJECT_ROOT/build"
TEMP_DIR="$BUILD_DIR/temp"
mkdir -p "$TEMP_DIR"

# Calculate required image size (rootfs size + extra space)
ROOTFS_SIZE=$(du -sm "$ROOTFS_DIR" | cut -f1)
IMAGE_SIZE=$((ROOTFS_SIZE + 200)) # Add 200MB for boot partition and extra space

echo "Creating disk image of ${IMAGE_SIZE}MB..."
dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1M count="$IMAGE_SIZE"

# Create partition table
echo "Creating partitions..."
parted -s "$OUTPUT_IMAGE" mklabel gpt
parted -s "$OUTPUT_IMAGE" mkpart primary fat32 1MiB 201MiB
parted -s "$OUTPUT_IMAGE" mkpart primary ext4 201MiB 100%
parted -s "$OUTPUT_IMAGE" set 1 boot on

# Set up loop device
LOOP_DEVICE=$(sudo losetup -f --show "$OUTPUT_IMAGE")
PARTITION1="${LOOP_DEVICE}p1"
PARTITION2="${LOOP_DEVICE}p2"

# Format partitions
echo "Formatting partitions..."
sudo mkfs.vfat -F 32 "$PARTITION1"
sudo mkfs.ext4 -F "$PARTITION2"

# Mount partitions
mkdir -p "$TEMP_DIR/boot" "$TEMP_DIR/rootfs"
sudo mount "$PARTITION1" "$TEMP_DIR/boot"
sudo mount "$PARTITION2" "$TEMP_DIR/rootfs"

# Copy kernel to boot partition
echo "Copying kernel to boot partition..."
sudo cp "$KERNEL_IMAGE" "$TEMP_DIR/boot/vmlinuz"

# Create device tree files for ARM Cortex-A76
echo "Creating device tree files..."
# This is a placeholder - you would need to include the actual DTB files for your target hardware
# sudo cp "$BUILD_DIR/kernel/linux/arch/arm64/boot/dts/your-specific-board.dtb" "$TEMP_DIR/boot/"

# Create boot script for U-Boot
cat > "$TEMP_DIR/uboot_boot.cmd" << EOF
setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait"
load \${devtype} \${devnum}:\${bootpart} \${kernel_addr_r} vmlinuz
booti \${kernel_addr_r} - \${fdt_addr}
EOF

# Compile boot script for U-Boot
# Note: In a real build environment, you would need mkimage tool from U-Boot
# sudo mkimage -A arm64 -O linux -T script -C none -n "Boot Script" -d "$TEMP_DIR/uboot_boot.cmd" "$TEMP_DIR/boot/boot.scr"

# Copy root filesystem
echo "Copying root filesystem..."
sudo cp -a "$ROOTFS_DIR"/* "$TEMP_DIR/rootfs/"

# Create /etc/fstab
cat > "$TEMP_DIR/rootfs/etc/fstab" << EOF
/dev/mmcblk0p1  /boot       vfat    defaults        0 2
/dev/mmcblk0p2  /           ext4    defaults        0 1
EOF

# Create startup script to run Python main.py
mkdir -p "$TEMP_DIR/rootfs/etc/init.d"
cat > "$TEMP_DIR/rootfs/etc/init.d/S99python" << EOF
#!/bin/sh
#
# Start Python application
#

case "\$1" in
  start)
    printf "Starting Python application: "
    cd /opt/corearm
    python main.py &
    echo "OK"
    ;;
  stop)
    printf "Stopping Python application: "
    killall python
    echo "OK"
    ;;
  restart|reload)
    "\$0" stop
    "\$0" start
    ;;
  *)
    echo "Usage: \$0 {start|stop|restart}"
    exit 1
esac

exit \$?
EOF

# Make startup script executable
chmod +x "$TEMP_DIR/rootfs/etc/init.d/S99python"

# Create /etc/inittab for proper system initialization
cat > "$TEMP_DIR/rootfs/etc/inittab" << EOF
# /etc/inittab
::sysinit:/etc/init.d/rcS
::respawn:/sbin/getty -L ttyS0 115200 vt100
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# Create /etc/init.d/rcS to run all init scripts
cat > "$TEMP_DIR/rootfs/etc/init.d/rcS" << EOF
#!/bin/sh
# Run all init scripts in /etc/init.d
for i in /etc/init.d/S??* ;do
    [ -x \$i ] && \$i start
done
EOF
chmod +x "$TEMP_DIR/rootfs/etc/init.d/rcS"

# Unmount partitions
echo "Unmounting partitions..."
sudo umount "$TEMP_DIR/boot"
sudo umount "$TEMP_DIR/rootfs"
sudo losetup -d "$LOOP_DEVICE"

# Clean up
rm -rf "$TEMP_DIR"

echo "Image created successfully: $OUTPUT_IMAGE"
echo "You can flash this image to your storage device using 'dd':"
echo "dd if=$OUTPUT_IMAGE of=/dev/sdX bs=4M status=progress" 