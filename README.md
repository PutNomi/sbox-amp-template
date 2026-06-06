# S&Box Dedicated Server (LINUX) — AMP Template

AMP template for hosting an [s&box](https://sbox.game) dedicated server via SteamCMD.

Based on the original template by [Hydrocut](https://github.com/hydrocut) / TeamKit. Fixed, cleaned up, and translated to English.

## Requirements

- [AMP](https://cubecoders.com/AMP) by CubeCoders
- SteamCMD (handled automatically by AMP)
- Linux: Docker-based AMP instance (standard on Linux — no extra setup needed)
---

## Installation

### 1. Add the template to AMP

In AMP, go to **Configuration → Instance Deployment → Instance Management → Configuration Repositories** and add:

```
PutNomi/sbox-amp-template:main
```

Click **Fetch Latest**, then go back to create a new instance using **S&Box Dedicated Server**.

### 2. Wait for setup

### 2. Run Update

If try run update will probaly get *```This task could not be completed: Performing Upgrade - For instance YOUR_INSTANCE - State: 3.```* or *```ERROR! Failed to install app '1892930' (Missing configuration)```* just try **start server again** (not the update button)


When running, setup will automatically:
1. Download server files via SteamCMD (app ID `1892930`)
2. *(Linux only)* Download the correct `sbox-server.sh` from this repo (replacing Steam's CRLF version)
3. *(Linux only)* Install .NET 10 runtime directly into the game directory
4. *(Linux only)* Create `.so` symlinks so s&box can find its native libraries
5. *(Linux only)* Mark scripts executable

### 3. Start the server

Hit **Start** in AMP. The console should show:

```
Loading game 'facepunch.sandbox'
SteamAPI_Init(): Loaded local 'steamclient.so' OK.
Connected to Steam
```

> **Note:** `SteamGameServer_Init: failed to init in authenticated mode` is expected if no Steam Game Server token is configured. The server runs in unauthenticated mode (no VAC, not listed in the server browser, but fully playable via direct connect).

---

## How it works on Linux

AMP on Linux runs instances inside a Docker container (`cubecoders/ampbase`, Debian 13). Several issues needed solving to get s&box working in this environment — the update pipeline handles all of them automatically:

| Problem | Fix |
|---|---|
| `sbox-server.sh` ships from Steam with Windows CRLF line endings | `FetchURL` stage overwrites it with the correct LF version from this repo |
| Docker container has no system `dotnet` | `linux-setup.sh` installs .NET 10 runtime directly into the game directory |
| s&box resolves `.so` paths relative to the `dotnet` binary location | `dotnet` is installed in the game root, and `.so` files are symlinked there too |
| `libengine2.so` bundles OpenSSL which conflicts with .NET's crypto → segfault | `LD_PRELOAD` in `sbox-server.sh` gives system libcrypto/libssl symbol priority |
| `~/.steam/sdk64/steamclient.so` doesn't persist (Docker HOME=/root is ephemeral) | `sbox-server.sh` recreates the symlink on every start |

---

## Troubleshooting

**Server exits immediately / segfault (exit 139)**
Check that the `LD_PRELOAD` line is present in `sbox-server.sh`. Run Update again to re-download the correct version.

**`exec: dotnet: not found`**
The .NET install step failed. Check the Update log for errors. You can run it manually:
```bash
GAME_DIR="/home/amp/.ampdata/instances/YOUR_INSTANCE/sbox-dedicated-server/1892930"
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --runtime dotnet --channel 10.0 --install-dir "$GAME_DIR"
```

**`.so` library errors on startup**
Run the symlink step manually:
```bash
GAME_DIR="/home/amp/.ampdata/instances/YOUR_INSTANCE/sbox-dedicated-server/1892930"
cd "$GAME_DIR"
for f in bin/linuxsteamrt64/*.so; do ln -sf "$f" "${f##*/}"; done
```

**Server starts then immediately stops after a game update**
Run **Update** in AMP — this re-downloads server files and re-runs the Linux setup automatically.

---

## References

- [s&box Dedicated Server docs](https://sbox.game/dev/doc/networking/dedicated-servers/)
- [SteamCMD docs](https://developer.valvesoftware.com/wiki/SteamCMD)
- [AMP by CubeCoders](https://cubecoders.com/AMP)
