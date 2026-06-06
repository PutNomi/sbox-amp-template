#!/bin/bash
# Linux post-download setup for s&box dedicated server (AMP / Docker)
# Run by the AMP update pipeline after SteamCMD downloads the server files.
# Usage: linux-setup.sh <game_dir>

set -e
GAME_DIR="${1%/}"  # strip trailing slash if present

if [ -z "$GAME_DIR" ]; then
    echo "[linux-setup] ERROR: No game directory specified."
    exit 1
fi

echo "[linux-setup] Game directory: $GAME_DIR"

# ---------------------------------------------------------------------------
# Step 1: Install .NET 10 runtime directly into the game directory.
# s&box resolves native library (.so) paths using dirname(/proc/self/exe),
# so the dotnet binary must live in the game directory itself.
# ---------------------------------------------------------------------------
if [ -f "$GAME_DIR/dotnet" ]; then
    echo "[linux-setup] .NET already installed, skipping."
else
    echo "[linux-setup] Installing .NET 10 runtime..."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
        --runtime dotnet \
        --channel 10.0 \
        --install-dir "$GAME_DIR"
    echo "[linux-setup] .NET 10 installed."
fi

# ---------------------------------------------------------------------------
# Step 2: Symlink all .so files from bin/linuxsteamrt64/ to the game root.
# s&box constructs absolute paths like <game_dir>/libtier0.so but the files
# actually live in bin/linuxsteamrt64/. Symlinks bridge the gap.
# ---------------------------------------------------------------------------
echo "[linux-setup] Creating .so symlinks..."
cd "$GAME_DIR"
for f in bin/linuxsteamrt64/*.so; do
    [ -e "$f" ] || continue
    ln -sf "$f" "${f##*/}"
done
echo "[linux-setup] Symlinks created."

echo "[linux-setup] Done."
