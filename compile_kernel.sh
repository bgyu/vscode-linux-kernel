#!/bin/bash

# Function to show an error message and exit
function error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if we are in a Linux kernel source directory
if [ ! -f Makefile ] || ! grep -q "KERNELVERSION =" Makefile; then
    error_exit "This script must be run in a Linux kernel source folder."
fi

# Backup the existing .config file if it exists
if [ -f .config ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE=".config.bak_$TIMESTAMP"
    echo "Backing up existing .config to $BACKUP_FILE"
    cp .config "$BACKUP_FILE" || error_exit "Failed to backup .config"
fi

# Update the configuration with required settings
echo "CONFIG_DEBUG_INFO=y" >> .config || error_exit "Failed to update CONFIG_DEBUG_INFO"
echo "CONFIG_GDB_SCRIPTS=y" >> .config || error_exit "Failed to update CONFIG_GDB_SCRIPTS"

# Save kernel configuration
make olddefconfig || error_exit "Failed to save kernel configuration"

# Compile the kernel
make -j$(nproc) || error_exit "Kernel compilation failed"

echo "Kernel configuration and compilation completed successfully."
