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

# Add fw_cfg entry if we have erl args
if [[ ${#ERL_ARGS[@]} -gt 0 ]]; then
    # Use printf to properly join arguments with spaces
    printf -v erl_string '%s ' "${ERL_ARGS[@]}"
    erl_string="${erl_string% }"  # Remove trailing space
    # Double any commas in the string for fw_cfg escaping
    erl_string="${erl_string//,/,,}"
    CMD+=("-fw_cfg" "name=opt/erl,string=$erl_string")
fi

# Execute QEMU with stdin/stdout connected
exec "${CMD[@]}"
