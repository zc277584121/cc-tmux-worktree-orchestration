---
name: tmux-worktree-split
description: Split development into multiple features with tmux, git worktrees, and Claude Code instances
argument-hint: "<feature1> <feature2> ... [--tmux-level session|window|pane]"
allowed-tools:
  - Bash
---

# tmux-worktree-split Command

This command creates parallel development environments by combining tmux, git worktrees, and Claude Code instances. Each feature gets its own isolated environment.

## User Input

The user has provided: `$ARGUMENTS`

## Your Task

Parse the user input and extract:

1. **Feature names**: Extract feature names from the input. These can be:
   - Space-separated words: `login signup dashboard`
   - Comma-separated: `login, signup, dashboard`
   - Natural language: "I want to develop login, signup and dashboard"
   - Chinese input: "登录、注册、仪表盘" → convert to `login signup dashboard`

2. **tmux level** (optional, default: `window`):
   - Look for `--tmux-level` flag followed by: `session`, `window`, or `pane`
   - Or natural language hints: "using sessions", "in separate windows", "as panes"
   - Chinese hints: "会话", "窗口", "面板"

3. **Base branch** (optional, default: current branch):
   - Look for `--base-branch` or `--base` flag

## Parsing Examples

| Input | Features | tmux-level |
|-------|----------|------------|
| `login signup dashboard` | login, signup, dashboard | window |
| `login signup --tmux-level pane` | login, signup | pane |
| `I want to develop auth and api using sessions` | auth, api | session |
| `feature1, feature2, feature3 as panes` | feature1, feature2, feature3 | pane |

## Execution

After parsing, execute the script using the `CLAUDE_PLUGIN_ROOT` environment variable:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/tmux-worktree-split.sh" \
  --features "<feature1> <feature2> ..." \
  --tmux-level "<session|window|pane>" \
  [--base-branch "<branch>"]
```

## Important Notes

- If no features are detected, ask the user to specify feature names
- Feature names should be valid for git branch names (no spaces, special chars)
- Convert any invalid characters to hyphens
- If the input is unclear, ask for clarification before executing
- The script will create worktrees relative to the user's current working directory
- The user is typically in their project's git root directory when running this command

## Post-Split Reminder (Important!)

**Git worktree does NOT copy untracked/ignored directories.** After the split completes, you MUST check for and remind the user about directories that won't be available in the new worktrees.

### Common untracked directories to check:

| Directory | Type | Suggested Action |
|-----------|------|------------------|
| `.venv/`, `venv/` | Python virtual env | Run `uv sync` or `pip install -r requirements.txt` in each worktree |
| `node_modules/` | Node.js dependencies | Run `npm install` or `pnpm install` in each worktree |
| `__pycache__/` | Python cache | Will be auto-regenerated, no action needed |
| `dataset/`, `data/` | Large data files | Consider symlink to shared location |
| `.env` | Environment config | Copy from main repo or create new |
| `build/`, `dist/` | Build artifacts | Will be regenerated on build, no action needed |

### Your task after script execution:

1. **Check** if any of these directories exist in the current project:
   ```bash
   ls -la | grep -E "^d.*(venv|node_modules|dataset|data)$"
   ```

2. **Check** `.gitignore` for other large ignored directories

3. **Remind the user** with a message like:
   > ⚠️ **Note:** The following directories are not tracked by git and won't be in the new worktrees:
   > - `.venv/` - You'll need to run `uv sync` in each worktree
   > - `node_modules/` - You'll need to run `npm install` in each worktree
   >
   > For large data directories, consider creating symlinks to a shared location.

4. **Only mention directories that actually exist** in the project - don't warn about irrelevant ones
