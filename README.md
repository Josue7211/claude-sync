# claude-sync

Sync your [Claude Code](https://claude.com/claude-code) configuration and projects across machines. No SSH, no passwords, no credential managers needed — just filesystem mounts and Syncthing.

## Architecture

**Claude config** (`~/.claude/`) syncs via **Syncthing** — bidirectional, automatic, conflict-free. Rules, skills, hooks, memory, and settings stay in sync across all your machines without lifting a finger.

**Code projects** live on a **NAS** (the canonical copy). Machines that need fast local builds (e.g., macOS over SMB) keep a local copy in `~/Documents/projects/` and use rsync to pull/push.

```
┌──────────────┐    Syncthing     ┌──────────────┐
│   Desktop    │ ◄──────────────► │   MacBook    │
│  ~/.claude/  │   (automatic)    │  ~/.claude/  │
└──────┬───────┘                  └──────┬───────┘
       │                                 │
       │ NFS mount                       │ SMB mount
       │ (direct access)                 │ (or local copy via rsync)
       │                                 │
       └──────────┐   ┌─────────────────┘
                  ▼   ▼
            ┌─────────────┐
            │     NAS     │
            │  /projects  │
            └─────────────┘
```

### Why this design?

| Layer | Tool | Why |
|-------|------|-----|
| Claude config | Syncthing | Small files, bidirectional, instant propagation, handles conflicts |
| Projects | NAS + rsync | Large repos with build artifacts; NFS gives native speed on Linux, rsync gives fast local copies on Mac |
| Network | Tailscale subnet routing | Works on LAN, coffee shop, anywhere with wifi — NAS is always reachable |

## Install

```bash
git clone https://github.com/Josue7211/claude-sync.git
cd claude-sync
./claude-sync setup
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/Josue7211/claude-sync/main/claude-sync \
  -o ~/.local/bin/claude-sync
chmod +x ~/.local/bin/claude-sync
```

### Requirements

- `bash`, `rsync`, `python3`, `curl`
- [Syncthing](https://syncthing.net/) — for Claude config sync
- NAS mounted via NFS (Linux) or SMB (macOS)
- [Tailscale](https://tailscale.com/) — optional, for remote access to NAS

### NAS setup

Mount your NAS projects directory so claude-sync can find it:

**Linux (NFS):**
```bash
# /etc/fstab
<NAS_IP>:/path/to/projects  /mnt/storage/projects  nfs  defaults  0  0
```

**macOS (SMB):**
```
Finder → Go → Connect to Server → smb://<NAS_IP>/projects
```

Or mount at `/Volumes/projects` or `/Volumes/Media/projects` — claude-sync auto-detects both.

### Syncthing setup

1. Install Syncthing on all machines
2. Share your `~/.claude/` folder between them
3. That's it — claude-sync detects the Syncthing folder automatically

## Commands

| Command | Description |
|---------|-------------|
| `claude-sync` | Force Syncthing to rescan `~/.claude/` (immediate sync) |
| `claude-sync pull-projects` | NAS → local copy (get latest before working) |
| `claude-sync push-projects` | Local copy → NAS (push changes back) |
| `claude-sync status` | Show Syncthing state, config file counts, NAS mount status |
| `claude-sync setup` | First-time setup: create dirs, symlink to PATH, check Syncthing |

## How it works

### Claude config (`claude-sync`)

Triggers a Syncthing rescan of the `~/.claude/` folder. Syncthing handles the rest — bidirectional sync to all connected devices. Your rules, skills, hooks, memory, agents, and CLAUDE.md stay identical everywhere.

### Project sync (`pull-projects` / `push-projects`)

Uses rsync with smart excludes (`node_modules/`, `target/`, `.next/`, `build/`, `dist/`, `.dart_tool/`, `ios/Pods/`, etc.) to copy projects between NAS and a local directory.

- **Desktop (Linux + NFS):** Works directly on the NAS mount — no copy needed. `pull-projects` detects this and skips.
- **MacBook (SMB):** SMB is too slow for builds (especially Cargo, Flutter). `pull-projects` copies to `~/Documents/projects/` for native speed. `push-projects` syncs changes back.

### Status (`status`)

Shows:
- Syncthing running state
- Number of rules, skills, hooks, and project memories
- NAS mount status and project counts
- Local copy status

## Migrating from v1

v1 used SSH + sshpass to push config between machines. v2 replaces all of that:

| | v1 | v2 |
|--|----|----|
| Config sync | SSH push (one-directional) | Syncthing (bidirectional, automatic) |
| Project sync | Not supported | NAS mounts + rsync |
| Auth | SSH keys or passwords | None (filesystem mounts) |
| Config file | `~/.config/claude-sync/config.json` | Not needed (auto-detects everything) |
| Dependencies | `ssh`, `sshpass` | `syncthing`, `rsync` |

You can safely delete `~/.config/claude-sync/` after upgrading.

## License

MIT
