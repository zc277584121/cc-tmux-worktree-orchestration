#!/bin/bash

# utils.sh
# Utility functions for tmux-worktree-orchestration

# Check if running inside tmux
is_inside_tmux() {
    [[ -n "$TMUX" ]]
}

# Get current tmux session name
get_current_session() {
    if is_inside_tmux; then
        tmux display-message -p '#S'
    else
        echo ""
    fi
}

# Check if a tmux session exists
session_exists() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

# Check if a git branch exists
branch_exists() {
    local branch_name="$1"
    git show-ref --verify --quiet "refs/heads/$branch_name"
}

# Check if a git worktree exists at path
worktree_exists() {
    local path="$1"
    [[ -d "$path" ]] && [[ -f "$path/.git" ]]
}

# Get the root of the git repository
get_git_root() {
    git rev-parse --show-toplevel
}

# Get the current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# List all worktrees
list_worktrees() {
    git worktree list
}

# Remove a worktree
remove_worktree() {
    local path="$1"
    local force="${2:-false}"

    if [[ "$force" == "true" ]]; then
        git worktree remove --force "$path"
    else
        git worktree remove "$path"
    fi
}

# Kill a tmux session
kill_session() {
    local session_name="$1"
    if session_exists "$session_name"; then
        tmux kill-session -t "$session_name"
        return 0
    fi
    return 1
}

# Validate feature name
validate_feature_name() {
    local name="$1"
    # Check if name is empty
    if [[ -z "$name" ]]; then
        return 1
    fi
    # Check for invalid characters (allow alphanumeric, hyphens, underscores)
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi
    return 0
}

# Convert string to lowercase
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Join array elements with delimiter
join_by() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf %s "$first" "${@/#/$delimiter}"
}
