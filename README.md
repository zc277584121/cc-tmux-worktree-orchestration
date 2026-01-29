# tmux-worktree-orchestration

A Claude Code Plugin that enables parallel AI-powered development by combining tmux, git worktrees, and multiple Claude Code instances.

## Why This Plugin?

### The Power of AI Concurrent Programming

Traditional development is sequential - you work on one feature, finish it, then move to the next. But with AI coding assistants like Claude Code, we can break this limitation. **AI doesn't get tired, doesn't lose context when switching tasks, and can work on multiple problems simultaneously.**

This plugin unleashes the full potential of AI-assisted development by allowing you to:
- **Run multiple Claude Code instances in parallel**, each focused on a different feature
- **Dramatically reduce development time** - what used to take days can now be done in hours
- **Maintain perfect isolation** - each feature has its own git branch and working directory, no conflicts

### Why tmux?

tmux is the perfect companion for AI concurrent programming:

- **Persistent Sessions**: SSH disconnected? Computer went to sleep? No problem. tmux sessions keep running. Your Claude Code instances continue working even when you're not connected.
- **Session Recovery**: Simply `tmux attach` to reconnect to all your running AI sessions instantly
- **Resource Efficient**: Unlike multiple terminal windows, tmux runs in a single process and uses minimal resources
- **Remote Friendly**: Perfect for running on remote servers - start your AI agents, disconnect, come back later to check results

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Your Development Flow                           │
└─────────────────────────────────────────────────────────────────────────┘

1. SPLIT: Create parallel development environments
   ┌──────────────┐
   │  Main Repo   │ ──── /tmux-worktree-split login signup api ────┐
   │    (main)    │                                                 │
   └──────────────┘                                                 │
                                                                    ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │                        tmux session                              │
   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
   │  │   Window 1  │  │   Window 2  │  │   Window 3  │              │
   │  │   login     │  │   signup    │  │     api     │              │
   │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │              │
   │  │ │ Claude  │ │  │ │ Claude  │ │  │ │ Claude  │ │              │
   │  │ │  Code   │ │  │ │  Code   │ │  │ │  Code   │ │              │
   │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │              │
   │  │             │  │             │  │             │              │
   │  │ Worktree:   │  │ Worktree:   │  │ Worktree:   │              │
   │  │ repo-login  │  │ repo-signup │  │ repo-api    │              │
   │  │             │  │             │  │             │              │
   │  │ Branch:     │  │ Branch:     │  │ Branch:     │              │
   │  │feature/login│  │feature/signup│ │ feature/api │              │
   │  └─────────────┘  └─────────────┘  └─────────────┘              │
   └──────────────────────────────────────────────────────────────────┘

2. DEVELOP: Work on features in parallel (AI does the heavy lifting!)
   - Each Claude Code instance works independently
   - No conflicts between features
   - Switch between windows with Ctrl+b n/p

3. MERGE: Combine everything back
   ┌──────────────────────────────────────────────────────────────────┐
   │                    /tmux-worktree-merge                          │
   └──────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
   ┌──────────────┐
   │  Main Repo   │  ← All features merged, worktrees cleaned up,
   │    (main)    │    tmux sessions closed, ready for next sprint!
   └──────────────┘
```

### State Management

The plugin automatically manages state between split and merge:

1. **On Split**: Creates `.worktree-split-state.md` in your project root
   - Records base branch, tmux configuration, all feature info
   - Copied to each worktree for easy access

2. **On Merge**: Reads state file and performs cleanup
   - Merges all feature branches back to base
   - Removes worktrees and cleans up branches
   - Kills tmux sessions
   - Deletes state file (won't be committed to git)

## Features

- **Parallel Development**: Work on multiple features simultaneously with AI
- **Git Worktrees**: Each feature gets its own worktree and branch
- **tmux Integration**: Organize environments as sessions, windows, or panes
- **Claude Code Auto-start**: Automatically starts Claude Code in each environment
- **State Tracking**: Automatic state management for seamless merge operations
- **Natural Language Support**: Parse feature names from natural language input

## Installation

In Claude Code, run:

```
/plugin marketplace add zc277584121/cc-tmux-worktree-orchestration

/plugin install tmux-worktree-orchestration
```

To update the plugin:

```
/plugin marketplace update

/plugin update tmux-worktree-orchestration
```

## Prerequisites

- **tmux**: Terminal multiplexer
  - macOS: `brew install tmux`
  - Ubuntu: `sudo apt install tmux`
  - Fedora: `sudo dnf install tmux`
- **git**: Version control (with worktree support)
- **Claude Code**: CLI tool

## Usage

### Split: Create Parallel Environments

```bash
# Create windows (default) for three features
/tmux-worktree-split login signup dashboard

# Create separate sessions for each feature
/tmux-worktree-split auth api --tmux-level session

# Create panes in a single window
/tmux-worktree-split feature1 feature2 --tmux-level pane

# Specify base branch
/tmux-worktree-split login signup --base-branch develop
```

Natural language also works:

```bash
/tmux-worktree-split I want to develop login, signup, and dashboard
/tmux-worktree-split auth and api using sessions
```

### Merge: Cleanup and Combine

When you're done developing:

```bash
# Merge all features and cleanup
/tmux-worktree-merge

# Skip merge (just cleanup tmux and worktrees)
/tmux-worktree-merge --skip-merge

# Force cleanup even if merge fails
/tmux-worktree-merge --force
```

### Options

#### Split Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tmux-level` | Organization level: `session`, `window`, or `pane` | `window` |
| `--base-branch` | Base branch for creating feature branches | Current branch |
| `--session-name` | tmux session name (for window/pane levels) | `dev` |

#### Merge Options

| Option | Description |
|--------|-------------|
| `--skip-merge` | Skip merging branches, only cleanup |
| `--force` | Force cleanup even if merge fails |

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

## Directory Structure

After running `/tmux-worktree-split login signup dashboard` in `my-project/`:

```
parent-directory/
├── my-project/                    # Original repo (main branch)
│   ├── .worktree-split-state.md   # State file (auto-deleted on merge)
│   └── (your project files)
├── my-project-login/              # Worktree for login feature
│   ├── .worktree-split-state.md   # Copy of state file
│   └── (project files on feature/login branch)
├── my-project-signup/             # Worktree for signup feature
│   ├── .worktree-split-state.md
│   └── (project files on feature/signup branch)
└── my-project-dashboard/          # Worktree for dashboard feature
    ├── .worktree-split-state.md
    └── (project files on feature/dashboard branch)
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
git worktree remove ../<project>-<feature-name>
```

### Claude Code doesn't start

Make sure `claude` command is available in your PATH:

```bash
which claude  # Should show path to claude
```

### Merge conflicts

If merge conflicts occur during `/tmux-worktree-merge`:

1. Use `--force` to skip failed merges and continue cleanup
2. Or manually resolve conflicts and run merge again

## Author

- **GitHub**: [zc277584121](https://github.com/zc277584121)
- **Repository**: [cc-tmux-worktree-orchestration](https://github.com/zc277584121/cc-tmux-worktree-orchestration)

## License

MIT
