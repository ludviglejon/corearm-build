#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/config.sh"

ROOTFS_DIR="$1"
if [ -z "$ROOTFS_DIR" ]; then
    echo "Error: Root filesystem directory not specified"
    exit 1
fi

BUILD_DIR="$PROJECT_ROOT/build"
PYTHON_BUILD_DIR="$BUILD_DIR/python"
CORES=$(nproc)

# Create Python build directory
mkdir -p "$PYTHON_BUILD_DIR"
cd "$PYTHON_BUILD_DIR"

# Download and extract Python source
if [ ! -f "Python-$PYTHON_VERSION.tar.xz" ]; then
    echo "Downloading Python $PYTHON_VERSION..."
    wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz"
fi

if [ ! -d "Python-$PYTHON_VERSION" ]; then
    echo "Extracting Python $PYTHON_VERSION..."
    tar -xf "Python-$PYTHON_VERSION.tar.xz"
fi

# Build Python for the target
cd "Python-$PYTHON_VERSION"
if [ ! -f "Makefile" ]; then
    echo "Configuring Python for cross-compilation..."
    
    # Create cross-compilation configuration
    cat > cross-build-config.site << EOF
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
EOF
    
    # Configure Python with GUI support (tk, tcl, X11)
    CONFIG_SITE=cross-build-config.site \
    CC="${CROSS_COMPILE}gcc" \
    CXX="${CROSS_COMPILE}g++" \
    AR="${CROSS_COMPILE}ar" \
    RANLIB="${CROSS_COMPILE}ranlib" \
    LD="${CROSS_COMPILE}ld" \
    ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-ensurepip=install \
        --with-system-ffi \
        --with-system-expat \
        --with-lto \
        --enable-optimizations \
        --with-computed-gotos \
        --host=aarch64-linux-gnu \
        --build=$(gcc -dumpmachine)
fi

# Build and install Python
echo "Building Python..."
make -j$CORES DESTDIR="$ROOTFS_DIR" altinstall

# Create a symlink for python3
ln -sf python3.9 "$ROOTFS_DIR/usr/bin/python3"
ln -sf python3 "$ROOTFS_DIR/usr/bin/python"

# Install pip and required packages for GUI
echo "Installing additional Python packages..."
cat > "$ROOTFS_DIR/tmp/install_packages.py" << EOF
#!/usr/bin/env python3
import subprocess
import sys

packages = [
    "pip",
    "wheel",
    "setuptools",
    "tk",
    "pygame",
    "PyQt5",
    "numpy",
]

for package in packages:
    print(f"Installing {package}...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])
EOF

# Note: In a real build, you'd need to do this in a QEMU environment 
# or use a cross-compilation approach for pip packages
echo "Note: In a real build environment, you would need to install Python packages using chroot or QEMU"

# Install the main.py script that will run on startup
mkdir -p "$ROOTFS_DIR/opt/corearm"
cat > "$ROOTFS_DIR/opt/corearm/main.py" << EOF
#!/usr/bin/env python3
"""
CoreARM main application
This script runs automatically on system startup
"""
import os
import sys
import time

print("CoreARM - Python environment starting...")

# Check if a user script exists and run it instead
USER_SCRIPT = "/home/user/main.py"
if os.path.exists(USER_SCRIPT):
    print(f"Found user script: {USER_SCRIPT}")
    print("Executing user script...")
    exec(open(USER_SCRIPT).read())
else:
    print("No user script found. Running default application.")
    
    # Try to import GUI libraries
    try:
        import tkinter as tk
        from tkinter import messagebox
        
        # Create simple GUI application if display is available
        if os.environ.get('DISPLAY'):
            root = tk.Tk()
            root.title("CoreARM")
            root.geometry("400x300")
            
            label = tk.Label(root, text="Welcome to CoreARM!")
            label.pack(pady=20)
            
            info_text = tk.Text(root, height=10, width=40)
            info_text.insert(tk.END, "System Information:\n")
            info_text.insert(tk.END, f"Python version: {sys.version}\n")
            info_text.insert(tk.END, f"User: {os.getenv('USER')}\n")
            info_text.insert(tk.END, f"Host: {os.uname().nodename}\n")
            info_text.insert(tk.END, "\nCreate your own application by placing")
            info_text.insert(tk.END, "\na main.py file in your home directory.")
            info_text.pack(pady=10)
            
            quit_button = tk.Button(root, text="Quit", command=root.destroy)
            quit_button.pack(pady=10)
            
            root.mainloop()
        else:
            print("No display available. Running in console mode.")
    except ImportError:
        print("GUI libraries not available. Running in console mode.")
    
    # Keep the system running
    print("Press Ctrl+C to exit")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Exiting...")
EOF

# Make the script executable
chmod +x "$ROOTFS_DIR/opt/corearm/main.py"

echo "Python setup completed!" 