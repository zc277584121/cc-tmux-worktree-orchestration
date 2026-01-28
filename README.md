# tmux-worktree-orchestration

A Claude Code Plugin that enables parallel development by combining tmux, git worktrees, and Claude Code instances. Split your development into multiple features, each with its own isolated environment.

## Features

- **Parallel Development**: Work on multiple features simultaneously
- **Git Worktrees**: Each feature gets its own worktree and branch
- **tmux Integration**: Organize environments as sessions, windows, or panes
- **Claude Code Auto-start**: Automatically starts Claude Code in each environment
- **Natural Language Support**: Parse feature names from natural language input

## Installation

In Claude Code, run:

```
/plugin marketplace add zc277584121/cc-tmux-worktree-orchestration
/plugin install tmux-worktree-orchestration@tmux-worktree-plugins
```

## Prerequisites

- **tmux**: Terminal multiplexer
  - macOS: `brew install tmux`
  - Ubuntu: `sudo apt install tmux`
  - Fedora: `sudo dnf install tmux`
- **git**: Version control (with worktree support)
- **Claude Code**: CLI tool (optional, for auto-start)

## Usage

### Basic Syntax

```
/tmux-worktree-orchestration:tmux-worktree-split <feature1> <feature2> ... [--tmux-level session|window|pane]
```

### Examples

#### Standard Format

```bash
# Create windows (default) for three features
/tmux-worktree-orchestration:tmux-worktree-split login signup dashboard

# Create separate sessions for each feature
/tmux-worktree-orchestration:tmux-worktree-split auth api --tmux-level session

# Create panes in a single window
/tmux-worktree-orchestration:tmux-worktree-split feature1 feature2 --tmux-level pane
```

#### Natural Language

```bash
# Claude will parse feature names from natural language
/tmux-worktree-orchestration:tmux-worktree-split I want to develop login, signup, and dashboard

# Specify tmux level naturally
/tmux-worktree-orchestration:tmux-worktree-split auth and api using sessions
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tmux-level` | Organization level: `session`, `window`, or `pane` | `window` |
| `--base-branch` | Base branch for creating feature branches | Current branch |
| `--session-name` | tmux session name (for window/pane levels) | `dev` |

## tmux Levels Explained

### Session Level (`--tmux-level session`)

Creates a separate tmux session for each feature. Best for completely isolated work.

```
Session: login     Session: signup     Session: dashboard
┌─────────────┐   ┌─────────────┐     ┌─────────────┐
│  Claude     │   │  Claude     │     │  Claude     │
│  Code       │   │  Code       │     │  Code       │
└─────────────┘   └─────────────┘     └─────────────┘
```

**Navigation:**
- List sessions: `tmux list-sessions` or `Ctrl+b s`
- Switch session: `tmux switch-client -t <name>`
- Attach session: `tmux attach -t <name>`

### Window Level (`--tmux-level window`) - Default

Creates windows within a single session. Good balance of isolation and accessibility.

```
Session: dev
┌─────────────────────────────────────────────┐
│  [0:login]  [1:signup]  [2:dashboard]       │
├─────────────────────────────────────────────┤
│                                             │
│              Claude Code                    │
│                                             │
└─────────────────────────────────────────────┘
```

**Navigation:**
- Next window: `Ctrl+b n`
- Previous window: `Ctrl+b p`
- Select by number: `Ctrl+b <number>`
- List windows: `Ctrl+b w`

### Pane Level (`--tmux-level pane`)

Creates panes within a single window. Best for quick context switching.

```
Session: dev
┌─────────────────────────────────────────────┐
│  login          │  signup                   │
│  Claude Code    │  Claude Code              │
├─────────────────┼───────────────────────────┤
│  dashboard      │                           │
│  Claude Code    │                           │
└─────────────────┴───────────────────────────┘
```

**Navigation:**
- Cycle panes: `Ctrl+b o`
- Arrow navigation: `Ctrl+b <arrow>`
- Zoom/unzoom: `Ctrl+b z`

## What Gets Created

For each feature, the plugin creates:

1. **Git Worktree**: `../worktrees/<feature-name>/`
2. **Feature Branch**: `feature/<feature-name>`
3. **tmux Environment**: Based on specified level
4. **Claude Code Instance**: Auto-started in each environment

## Directory Structure

After running with features `login`, `signup`, `dashboard`:

```
your-repo/
├── (your project files)
└── ../worktrees/
    ├── login/           # Worktree for login feature
    │   └── (project files on feature/login branch)
    ├── signup/          # Worktree for signup feature
    │   └── (project files on feature/signup branch)
    └── dashboard/       # Worktree for dashboard feature
        └── (project files on feature/dashboard branch)
```

## Cleanup

### Remove Worktrees

```bash
# Remove a specific worktree
git worktree remove ../worktrees/login

# Force remove (if there are changes)
git worktree remove --force ../worktrees/login

# List all worktrees
git worktree list
```

### Kill tmux Sessions

```bash
# Kill a specific session
tmux kill-session -t login

# Kill all sessions
tmux kill-server
```

### Delete Feature Branches

```bash
# Delete local branch
git branch -d feature/login

# Force delete
git branch -D feature/login
```

## Troubleshooting

### "tmux is not installed"

Install tmux using your package manager:

```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux
```

### "Not in a git repository"

Make sure you're in a git repository when running the command:

```bash
cd /path/to/your/repo
git status  # Should show repo status
```

### "Worktree already exists"

The plugin will reuse existing worktrees. To start fresh:

```bash
git worktree remove ../worktrees/<feature-name>
```

### Claude Code doesn't start

Make sure `claude` command is available in your PATH:

```bash
which claude  # Should show path to claude
```

## Author

- **GitHub**: [zc277584121](https://github.com/zc277584121)
- **Repository**: [cc-tmux-worktree-orchestration](https://github.com/zc277584121/cc-tmux-worktree-orchestration)

## License

MIT
