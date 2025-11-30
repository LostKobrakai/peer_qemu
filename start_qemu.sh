#!/bin/bash

# QEMU starter script with fw_cfg support
# Usage: ./start_qemu.sh [qemu-options] -- [args...]
# Arguments after -- will be passed as single fw_cfg entry named "erl"

set -e

# Default QEMU binary
QEMU_BIN="qemu-system-aarch64"

# Arrays to store arguments
QEMU_OPTS=()
ERL_ARGS=()

# Parse arguments
parsing_erl=false
for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
        parsing_erl=true
        continue
    fi

    if [[ "$parsing_erl" == true ]]; then
        ERL_ARGS+=("$arg")
    else
        QEMU_OPTS+=("$arg")
    fi
done

# Check if QEMU binary exists
if ! command -v "$QEMU_BIN" &> /dev/null; then
    echo "Error: $QEMU_BIN not found in PATH" >&2
    exit 1
fi

# Build final command
CMD=("$QEMU_BIN" "${QEMU_OPTS[@]}")

# Execute QEMU with stdin/stdout connected
exec "${CMD[@]}"
