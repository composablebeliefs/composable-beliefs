# Neovim + Terminal Multiplexer Collaborative Editing Workflow

**Date:** 2026-03-14
**Status:** active

## What This Is

A workflow where the agent controls a neovim instance running in a terminal multiplexer split pane. The user says "open the cookbook" or "take me to the graph module" and the agent navigates them there. The user edits and reads in neovim while the agent works in its own pane.

## Setup

### Neovim config

Location: `~/.config/nvim/init.lua`

Minimal config with:
- **lazy.nvim** - plugin manager (bootstraps itself on first run)
- **nvim-tree** - file tree sidebar (replaces netrw)
- **nvim-web-devicons** - file type icons in the tree
- Basic settings: line numbers, 2-space tabs, termguicolors

Plugins stored at: `~/.local/share/nvim/lazy/`

### nvopen script

Location: `~/.local/bin/nvopen`

CLI tool that finds the "editor" neovim surface in the current multiplexer workspace and sends commands to it.

```bash
nvopen /path/to/file          # Open file in nvim
nvopen /path/to/dir           # Open directory in nvim
nvopen --tree                 # Toggle the file tree sidebar
nvopen --find                 # Find current file in tree
nvopen --cmd ':some command'  # Send arbitrary nvim command
```

**How it works:**
1. Scans all pane surfaces in the current multiplexer workspace for one titled "editor"
2. If none found, creates a right split, launches nvim, and names the tab "editor"
3. Sends the `:e <path>` command (or other command) to that surface via the multiplexer's send API

**Path note:** `~/.local/bin` is in the user's PATH (configured in `~/.zshrc`) but may not be loaded in the agent's shell. Use the full path `~/.local/bin/nvopen` from the agent.

## How to Use (Agent Onboarding)

### Starting a session

Create the editor pane and name it. Exact commands depend on your terminal multiplexer. The general pattern:

1. Create a new pane (right split or new window)
2. Name the tab/pane "editor"
3. Launch nvim in that pane

Or just run `nvopen` with any file - it auto-creates the editor if none exists.

### Navigating the user to a file

Always use absolute paths:

```bash
~/.local/bin/nvopen /absolute/path/to/file.json
```

**Never use relative paths.** The nvim instance's cwd may be `~` or anywhere else. Always resolve to absolute paths.

### Showing the file tree

```bash
~/.local/bin/nvopen --find    # Opens tree focused on current file
~/.local/bin/nvopen --tree    # Toggles tree open/closed
```

### Sending arbitrary vim commands

```bash
~/.local/bin/nvopen --cmd ':set wrap'
~/.local/bin/nvopen --cmd ':NvimTreeCollapse'
```

### Finding the editor surface

If you need to interact with the multiplexer directly (beyond what nvopen provides), scan panes for one titled "editor" using the multiplexer's JSON API.

### Multiplexer send gotchas

- `send` types text into the surface as if the user typed it
- `send-key` sends a single keypress (Enter, Escape, etc.)
- For vim commands, send the command string then send-key Enter
- For vim keybindings (like Space+f), just send the key sequence - no Enter needed
- If nvim is in insert mode, commands won't work - send Escape first
- "Surface is not a terminal" error means vim or another program is running in a mode the multiplexer can't send to - try a different approach

## User's Neovim Keybindings

| Key | Action |
|---|---|
| Space+e | Toggle file tree sidebar |
| Space+f | Find current file in tree |

### In nvim-tree (file tree sidebar)

| Key | Action |
|---|---|
| Enter | Open file / expand folder |
| Ctrl+] | Change tree root to folder under cursor (move into) |
| - | Go up one directory |
| a | Create file or directory |
| d | Delete |
| r | Rename |
| H | Toggle hidden files |
| ? | Show all keybindings |

## Architecture Note

The surface ID (e.g. surface:14) is ephemeral - it changes every multiplexer session. The tab title "editor" is the stable identifier. nvopen uses the title to discover the surface dynamically, so it works across sessions without hardcoded IDs.

Multiple workspaces can each have their own "editor" surface. nvopen finds the one in the current workspace (via an environment variable set automatically in multiplexer terminals).
