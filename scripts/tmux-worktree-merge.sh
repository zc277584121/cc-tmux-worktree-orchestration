#!/bin/bash

# tmux-worktree-merge.sh
# Merge feature branches back to base branch and cleanup worktrees/tmux

set -e

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# State file name
STATE_FILE=".worktree-split-state.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
SKIP_MERGE=false
FORCE=false

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Merge feature branches back to base branch and cleanup worktrees/tmux.

Options:
  --skip-merge        Skip merging branches (only cleanup tmux and worktrees)
  --force             Force cleanup even if merge fails
  -h, --help          Show this help message

The script reads state from $STATE_FILE in the current directory.
EOF
    exit 1
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-merge)
                SKIP_MERGE=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Check if state file exists
check_state_file() {
    if [[ ! -f "$STATE_FILE" ]]; then
        print_error "State file not found: $STATE_FILE"
        print_info "Make sure you're in the project root directory where split was executed."
        exit 1
    fi
}

# Parse state file (simple parsing for the YAML-like frontmatter)
parse_state_file() {
    local in_frontmatter=false
    local in_features=false

    BASE_BRANCH=""
    TMUX_LEVEL=""
    SESSION_NAME=""
    FEATURES=()
    BRANCHES=()
    WORKTREE_PATHS=()

    while IFS= read -r line; do
        # Check frontmatter boundaries
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break  # End of frontmatter
            else
                in_frontmatter=true
                continue
            fi
        fi

        if $in_frontmatter; then
            # Parse key-value pairs
            if [[ "$line" =~ ^base_branch:\ *(.+)$ ]]; then
                BASE_BRANCH="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^tmux_level:\ *(.+)$ ]]; then
                TMUX_LEVEL="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^session_name:\ *(.+)$ ]]; then
                SESSION_NAME="${BASH_REMATCH[1]}"
            elif [[ "$line" == "features:" ]]; then
                in_features=true
            elif $in_features; then
                if [[ "$line" =~ ^\ *-\ *name:\ *(.+)$ ]]; then
                    FEATURES+=("${BASH_REMATCH[1]}")
                elif [[ "$line" =~ ^\ *branch:\ *(.+)$ ]]; then
                    BRANCHES+=("${BASH_REMATCH[1]}")
                elif [[ "$line" =~ ^\ *worktree_path:\ *(.+)$ ]]; then
                    WORKTREE_PATHS+=("${BASH_REMATCH[1]}")
                fi
            fi
        fi
    done < "$STATE_FILE"

    # Validate parsed data
    if [[ -z "$BASE_BRANCH" ]]; then
        print_error "Could not parse base_branch from state file"
        exit 1
    fi

    if [[ ${#FEATURES[@]} -eq 0 ]]; then
        print_error "No features found in state file"
        exit 1
    fi

    print_info "Parsed state file:"
    print_info "  Base branch: $BASE_BRANCH"
    print_info "  tmux level: $TMUX_LEVEL"
    print_info "  Session name: $SESSION_NAME"
    print_info "  Features: ${FEATURES[*]}"
}

# Kill tmux sessions/windows
cleanup_tmux() {
    print_info "Cleaning up tmux..."

    case $TMUX_LEVEL in
        session)
            # Kill each feature's session
            for feature in "${FEATURES[@]}"; do
                if tmux has-session -t "$feature" 2>/dev/null; then
                    tmux kill-session -t "$feature"
                    print_success "Killed tmux session: $feature"
                else
                    print_warning "tmux session not found: $feature"
                fi
            done
            ;;
        window|pane)
            # Kill the whole session
            if [[ -n "$SESSION_NAME" ]] && tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                tmux kill-session -t "$SESSION_NAME"
                print_success "Killed tmux session: $SESSION_NAME"
            else
                print_warning "tmux session not found: $SESSION_NAME"
            fi
            ;;
    esac
}

# Merge feature branches to base branch
merge_branches() {
    if $SKIP_MERGE; then
        print_warning "Skipping branch merge (--skip-merge specified)"
        return 0
    fi

    print_info "Merging feature branches to $BASE_BRANCH..."

    # First, switch to base branch
    git checkout "$BASE_BRANCH"

    local merge_failed=false

    for i in "${!BRANCHES[@]}"; do
        local branch="${BRANCHES[$i]}"
        local feature="${FEATURES[$i]}"

        print_info "Merging $branch..."

        if git merge --no-ff "$branch" -m "Merge $branch into $BASE_BRANCH"; then
            print_success "Merged: $branch"
        else
            print_error "Merge conflict in $branch"
            if $FORCE; then
                print_warning "Aborting merge and continuing (--force specified)"
                git merge --abort
            else
                print_error "Please resolve conflicts manually or use --force to skip"
                merge_failed=true
                git merge --abort
            fi
        fi
    done

    if $merge_failed && ! $FORCE; then
        print_error "Some merges failed. Use --force to continue with cleanup anyway."
        exit 1
    fi
}

# Remove worktrees
cleanup_worktrees() {
    print_info "Removing worktrees..."

    for i in "${!WORKTREE_PATHS[@]}"; do
        local path="${WORKTREE_PATHS[$i]}"
        local feature="${FEATURES[$i]}"

        if [[ -d "$path" ]]; then
            git worktree remove --force "$path" 2>/dev/null || rm -rf "$path"
            print_success "Removed worktree: $path"
        else
            print_warning "Worktree not found: $path"
        fi
    done
}

# Delete feature branches
cleanup_branches() {
    if $SKIP_MERGE; then
        print_warning "Skipping branch deletion (--skip-merge specified, branches may still be needed)"
        return 0
    fi

    print_info "Deleting feature branches..."

    for branch in "${BRANCHES[@]}"; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            git branch -D "$branch"
            print_success "Deleted branch: $branch"
        else
            print_warning "Branch not found: $branch"
        fi
    done
}

# Remove state file
cleanup_state_file() {
    if [[ -f "$STATE_FILE" ]]; then
        rm "$STATE_FILE"
        print_success "Removed state file: $STATE_FILE"
    fi
}

# Main function
main() {
    echo ""
    echo "=========================================="
    echo "  tmux-worktree-merge"
    echo "=========================================="
    echo ""

    parse_args "$@"
    check_state_file
    parse_state_file

    echo ""
    print_info "Starting merge and cleanup process..."
    echo ""

    # Step 1: Kill tmux sessions/windows first (so we're not inside them)
    cleanup_tmux

    # Step 2: Merge branches
    merge_branches

    # Step 3: Remove worktrees
    cleanup_worktrees

    # Step 4: Delete feature branches
    cleanup_branches

    # Step 5: Remove state file
    cleanup_state_file

    echo ""
    echo "=========================================="
    echo "  Merge Complete!"
    echo "=========================================="
    echo ""
    print_success "All features have been merged to: $BASE_BRANCH"
    echo ""
}

# Run main
main "$@"
