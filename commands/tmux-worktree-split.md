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

**Git worktree does NOT copy untracked/ignored files and directories.** After the split completes, you MUST analyze the project and remind the user about important untracked items.

### Your task after script execution:

1. **Read `.gitignore`** to understand what patterns are ignored in this project

2. **Check project directory structure** (use `ls -la`) to see what directories/files actually exist

3. **Identify untracked items that may affect development** by cross-referencing:
   - Items that exist in the project AND match `.gitignore` patterns
   - Focus on items that are important for development (dependencies, data, configs)
   - Ignore auto-generated caches like `__pycache__/`, `.pytest_cache/`, `build/`, `dist/` - these will regenerate

4. **Provide specific recommendations** based on what you find:

   | Type | Examples | Suggested Action |
   |------|----------|------------------|
   | Python virtual env | `.venv/`, `venv/` | Run `uv sync` or `pip install -r requirements.txt` in each worktree |
   | Node.js dependencies | `node_modules/` | Run `npm install` or `pnpm install` in each worktree |
   | Environment config | `.env`, `.env.local` | Copy from main repo: `cp ../<project>/.env .` |
   | Large data files | datasets, models, etc. | Create symlink: `ln -s /path/to/shared/data ./data` |
   | IDE settings | `.idea/`, `.vscode/` | Usually OK to skip, will regenerate |

5. **Format your reminder** like this:
   > ⚠️ **Note:** The following items are not tracked by git and won't be in the new worktrees:
   > - `.venv/` - Run `uv sync` to recreate
   > - `.env` - Copy from main repo: `cp ../my-project/.env .`
   >
   > Auto-generated directories (`__pycache__/`, etc.) will regenerate automatically.

**Key principle:** Only warn about items that actually exist AND are in `.gitignore` AND matter for development. Don't guess based on directory names alone.
