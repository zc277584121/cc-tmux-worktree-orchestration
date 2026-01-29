---
name: tmux-worktree-merge
description: Merge feature branches back to base branch and cleanup worktrees/tmux
argument-hint: "[--skip-merge] [--force]"
allowed-tools:
  - Bash
---

# tmux-worktree-merge Command

This command merges feature branches back to the base branch and cleans up all worktrees and tmux sessions/windows created by `tmux-worktree-split`.

## User Input

The user has provided: `$ARGUMENTS`

## Your Task

Parse the user input and extract options:

1. **--skip-merge** (optional): Skip merging branches, only cleanup tmux and worktrees
   - Natural language hints: "just cleanup", "skip merge", "only cleanup", "don't merge"
   - Chinese hints: "只清理", "跳过合并", "不合并"

2. **--force** (optional): Force cleanup even if merge fails
   - Natural language hints: "force", "force cleanup"
   - Chinese hints: "强制", "强制清理"

## Execution

Execute the merge script. The script is located in the `scripts/` directory of this plugin.

**IMPORTANT**: Use the Bash tool to run the script. The script path relative to this command file is `../scripts/tmux-worktree-merge.sh`.

For example, if this file is at `/path/to/plugin/commands/tmux-worktree-merge.md`, then the script is at `/path/to/plugin/scripts/tmux-worktree-merge.sh`.

Execute the script with the extracted options:

```bash
bash "<plugin-root>/scripts/tmux-worktree-merge.sh" [--skip-merge] [--force]
```

Replace `<plugin-root>` with the actual plugin directory path (one level up from this command file).

## What the script does

1. **Reads state file**: Loads `.worktree-split-state.md` from current directory
2. **Kills tmux sessions/windows**: Cleans up the tmux environments
3. **Merges branches**: Merges each feature branch back to the base branch (unless --skip-merge)
4. **Removes worktrees**: Deletes the worktree directories
5. **Deletes feature branches**: Removes the feature branches (unless --skip-merge)
6. **Removes state file**: Cleans up the state file from all locations

## Important Notes

- The script must be run from a directory containing `.worktree-split-state.md`
- If merge conflicts occur, the script will stop unless --force is specified
- Use --skip-merge if you want to manually handle the merge later
- All cleanup is permanent - make sure your work is committed before running
