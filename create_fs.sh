#!/bin/bash

# Function to show an error message and exit
function error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Variables
DISK_IMAGE="filesystem.img"
MOUNT_POINT="mnt"
DISK_SIZE_MB=64
# Assuming BusyBox is installed at /usr/sbin/busybox (Fedora 41)
BUSYBOX_PATH="/usr/sbin/busybox" 

# Step 0: Check if BusyBox is installed
if [ ! -x "$BUSYBOX_PATH" ]; then
    echo "BusyBox is not installed. Please install BusyBox and ensure it is available at $BUSYBOX_PATH."
    exit 1
fi

# Step 1: Create a Disk Image
if [ -f "$DISK_IMAGE" ]; then
    echo "$DISK_IMAGE already exists. Skip."
    exit 0
fi

echo "Creating disk image $DISK_IMAGE with size ${DISK_SIZE_MB}MB..."
dd if=/dev/zero of="$DISK_IMAGE" bs=1M count="$DISK_SIZE_MB" || error_exit "Failed to create disk image"

# Step 2: Format the Disk Image with a Filesystem
echo "Formatting disk image with ext4 filesystem..."
mkfs.ext4 "$DISK_IMAGE" || error_exit "Failed to format disk image"

# Step 3: Create a Mount Point
if [ -d "$MOUNT_POINT" ]; then
    echo "$MOUNT_POINT already exists. Removing it."
    sudo rm -rf "$MOUNT_POINT" || error_exit "Failed to remove existing $MOUNT_POINT"
fi
mkdir "$MOUNT_POINT" || error_exit "Failed to create mount point"

# Step 4: Mount the Disk Image
echo "Mounting disk image..."
sudo mount -o loop "$DISK_IMAGE" "$MOUNT_POINT" || error_exit "Failed to mount disk image"

# Step 5: Populate the Filesystem and Set Up Directories
echo "Setting up directories..."
sudo mkdir -p "$MOUNT_POINT/bin" "$MOUNT_POINT/sbin" "$MOUNT_POINT/usr/bin" \
    "$MOUNT_POINT/usr/sbin" "$MOUNT_POINT/dev" "$MOUNT_POINT/proc" \
    "$MOUNT_POINT/sys" "$MOUNT_POINT/tmp" "$MOUNT_POINT/etc" \
    "$MOUNT_POINT/lib" "$MOUNT_POINT/lib64" "$MOUNT_POINT/root" || error_exit "Failed to create directories"
sudo chmod 1777 "$MOUNT_POINT/tmp" || error_exit "Failed to set permissions on /tmp"

# Step 6: Copy BusyBox
echo "Copying BusyBox to /bin..."
sudo cp "$BUSYBOX_PATH" "$MOUNT_POINT/bin/" || error_exit "Failed to copy BusyBox"

# Step 7: Set Up Symlinks for BusyBox
echo "Setting up symlinks for BusyBox..."
sudo chroot "$MOUNT_POINT" /bin/busybox --install -s || error_exit "Failed to set up BusyBox symlinks"

# Step 8: Create the init Script
echo "Creating init script..."
sudo bash -c "cat > $MOUNT_POINT/init <<EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo \"Welcome to the minimal real filesystem!\"
exec /bin/sh
EOF"
sudo chmod +x "$MOUNT_POINT/init" || error_exit "Failed to make init script executable"

# Step 9: Create Device Nodes
echo "Creating device nodes..."
sudo mknod "$MOUNT_POINT/dev/null" c 1 3 || error_exit "Failed to create /dev/null"
sudo mknod "$MOUNT_POINT/dev/console" c 5 1 || error_exit "Failed to create /dev/console"

# Step 10: Unmount the Disk Image
echo "Unmounting disk image..."
sudo umount "$MOUNT_POINT" || error_exit "Failed to unmount disk image"

# Step 11: Clean Up
rm -rf "$MOUNT_POINT" || error_exit "Failed to remove mount point"

echo "Testing filesystem created successfully in $DISK_IMAGE."
