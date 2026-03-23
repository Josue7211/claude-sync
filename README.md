# claude-sync

Sync your [Claude Code](https://claude.com/claude-code) configuration across machines over SSH.

Claude Code's `.claude/` directory stores your project memory, rules, agents, skills, hooks, and MCP configs — but none of it syncs across devices. **claude-sync** fixes that.

## What it syncs

| Item | What it is |
|------|-----------|
| `settings.json` | Plugins, hooks, permissions, preferences |
| `rules/` | Modular instruction files (path-scoped or global) |
| `agents/` | Custom agent definitions |
| `skills/` | Custom skill workflows |
| `commands/` | Custom slash commands |
| `hooks/` | Hook scripts |
| `.mcp.json` | MCP server configurations |

## Install

```bash
git clone https://github.com/aparcedodev/claude-sync.git
cd claude-sync
./install.sh
```

Or copy the script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/aparcedodev/claude-sync/main/claude-sync -o ~/.local/bin/claude-sync
chmod +x ~/.local/bin/claude-sync
```

### Requirements

- `bash`, `python3`, `rsync`, `ssh`
- `sshpass` (only if using password auth)

## Quick start

```bash
# Initialize config
claude-sync init

# Add a target machine
claude-sync add macbook --host 192.168.1.50 --user me --password mypass

# Or with SSH key auth (no --password)
claude-sync add server --host 10.0.0.5 --user deploy

# Push your config
claude-sync push

# Push to a specific target
claude-sync push macbook

# Check what's different
claude-sync diff macbook

# See full status
claude-sync status
```

## How it works

```
┌─────────────────┐         SSH/rsync          ┌─────────────────┐
│  Source Machine  │ ────────────────────────▶   │  Target Machine  │
│                  │                             │                  │
│  ~/.claude/      │         push                │  ~/.claude/      │
│  ├── settings    │ ──────────────────────────▶ │  ├── settings    │
│  ├── rules/      │  (paths auto-rewritten)     │  ├── rules/      │
│  ├── agents/     │                             │  ├── agents/     │
│  ├── skills/     │                             │  ├── skills/     │
│  └── hooks/      │                             │  └── hooks/      │
│                  │                             │                  │
│  ~/.mcp.json     │ ──────────────────────────▶ │  ~/.mcp.json     │
└─────────────────┘                             └─────────────────┘
```

### Path mappings

When syncing between Linux and macOS (or any two machines with different home directories), paths in `settings.json` are automatically rewritten. For example:

- `/home/alice/.claude/hooks/` → `/Users/alice/.claude/hooks/`

This is configured per target and auto-detected during `claude-sync add`.

## Configuration

Config lives at `~/.config/claude-sync/config.json`:

```json
{
  "source": {
    "claudeDir": "/home/user/.claude",
    "mcpJson": "/home/user/.mcp.json"
  },
  "sync": [
    "settings.json",
    "rules",
    "agents",
    "skills",
    "commands",
    "hooks",
    ".mcp.json"
  ],
  "targets": {
    "macbook": {
      "host": "192.168.1.50",
      "user": "me",
      "auth": "password",
      "password": "mypass",
      "port": 22,
      "remoteHome": "/Users/me",
      "pathMappings": {
        "/home/user/": "/Users/me/"
      }
    }
  }
}
```

### Customizing what syncs

Edit the `sync` array to add or remove items. Any path relative to `~/.claude/` works:

```json
{
  "sync": [
    "settings.json",
    "rules",
    "agents",
    "skills",
    "commands",
    "hooks",
    ".mcp.json",
    "todos"
  ]
}
```

## Commands

| Command | Description |
|---------|-------------|
| `init` | Create config file |
| `add <name>` | Add a sync target |
| `remove <name>` | Remove a target |
| `list` | Show targets with online/offline status |
| `push [target]` | Sync to all targets (or one) |
| `push --dry-run` | Preview what would sync |
| `diff <target>` | Compare local vs remote |
| `status` | Full status overview |

## Why not just use dotfiles/git?

You could commit `.claude/` to a dotfiles repo, but:

- **`settings.json` contains machine-specific paths** (hook scripts, etc.) that differ between Linux/macOS
- **MCP server configs may reference local services** with different IPs per network
- **You'd need to manually pull on each machine** after every change

claude-sync handles path rewriting automatically and pushes in one command.

## CLAUDE.md sync

claude-sync handles config files. For `CLAUDE.md` (project instructions), the recommended approach is:

1. Store a master `CLAUDE.md` on shared storage (NAS, cloud drive, etc.)
2. Each machine's `~/.claude/CLAUDE.md` imports it:

```markdown
# User-Level Instructions
@/path/to/shared/CLAUDE.md
```

This way instructions stay in sync without copying files.

## License

MIT
