#!/bin/bash

# Function to show an error message and exit
function error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Step 1: Check if we are in a Linux kernel source directory
if [ ! -f Makefile ] || ! grep -q "KERNELVERSION =" Makefile; then
    error_exit "This script must be run in a Linux kernel source folder."
fi

# Step 2: Generate compile_commands.json
echo "Generating compile_commands.json..."
if [ ! -x ./scripts/clang-tools/gen_compile_commands.py ]; then
    error_exit "gen_compile_commands.py script not found or not executable."
fi
python3 ./scripts/clang-tools/gen_compile_commands.py || error_exit "Failed to generate compile_commands.json."

# Step 3: Update ~/.gdbinit with add-auto-load-safe-path
GDBINIT_PATH="$HOME/.gdbinit"
CURRENT_WORKING_FOLDER=$(pwd)
SAFE_PATH_ENTRY="add-auto-load-safe-path $CURRENT_WORKING_FOLDER"

echo "Updating ~/.gdbinit with the current working folder..."
if [ ! -f "$GDBINIT_PATH" ]; then
    echo "~/.gdbinit does not exist. Creating it..."
    echo "$SAFE_PATH_ENTRY" > "$GDBINIT_PATH" || error_exit "Failed to create ~/.gdbinit."
else
    if grep -Fxq "$SAFE_PATH_ENTRY" "$GDBINIT_PATH"; then
        echo "~/.gdbinit already contains the entry. No update needed."
    else
        echo "$SAFE_PATH_ENTRY" >> "$GDBINIT_PATH" || error_exit "Failed to update ~/.gdbinit."
    fi
fi

echo "Script completed successfully."
