#!/bin/bash

# Function to kill existing qemu-system-x86_64 process if it exists
function kill_qemu() {
    if pkill -f qemu-system-x86_64 2>/dev/null; then
        echo "Killed existing qemu-system-x86_64 process."
    else
        echo "No qemu-system-x86_64 process found."
    fi
}

# Kill any existing qemu-system-x86_64 process
kill_qemu

# Start a new qemu-system-x86_64 instance
echo "Starting qemu-system-x86_64..."
# qemu-system-x86_64 \
#     -kernel arch/x86_64/boot/bzImage \
#     -s -S \
#     -append "nokaslr root=/dev/sda rw console=ttyS0 init=/init loglevel=8" \
#     -drive file=filesystem.img,format=raw,if=ide \
#     -serial tcp::4444,server,nowait -display none -daemonize || {
#     echo "Failed to start qemu-system-x86_64."
#     exit 1
# }

# Use tail -f serial.log to view the Kernel output during debugging
qemu-system-x86_64 \
    -kernel arch/x86_64/boot/bzImage \
    -s -S \
    -append "nokaslr root=/dev/sda rw console=ttyS0 init=/init loglevel=8" \
    -drive file=filesystem.img,format=raw,if=ide \
    -serial file:serial.log -display none -daemonize || {
    echo "Failed to start qemu-system-x86_64."
    exit 1
}

echo "qemu-system-x86_64 started successfully."
