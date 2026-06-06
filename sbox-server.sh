#!/bin/bash
# s&box dedicated server launcher for Linux (AMP / Docker)
# This file is downloaded by the AMP update pipeline to replace the CRLF version from Steam.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add game libraries to the search path
export LD_LIBRARY_PATH="$SCRIPT_DIR/bin/linuxsteamrt64:$LD_LIBRARY_PATH"

# Fix OpenSSL symbol conflict: libengine2.so bundles its own OpenSSL which pollutes
# the global symbol table. Preloading system libcrypto/libssl gives their symbols
# priority and prevents a segfault on startup.
export LD_PRELOAD=/lib/x86_64-linux-gnu/libcrypto.so.3:/lib/x86_64-linux-gnu/libssl.so.3

# Steam SDK needs steamclient.so in ~/.steam/sdk64/. HOME=/root inside the Docker
# container and is not persisted, so recreate the symlink on every start.
mkdir -p ~/.steam/sdk64
ln -sf "$SCRIPT_DIR/steamclient.so" ~/.steam/sdk64/steamclient.so

# Use the locally installed dotnet binary. s&box resolves native library paths
# relative to the dotnet executable, so it must live in the game directory.
exec "$SCRIPT_DIR/dotnet" "$SCRIPT_DIR/sbox-server.dll" "$@"
