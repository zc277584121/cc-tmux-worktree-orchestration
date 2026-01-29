#!/bin/bash

# tmux-worktree-split.sh
# Create parallel development environments with tmux, git worktrees, and Claude Code

set -e

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# State file name
STATE_FILE=".worktree-split-state.md"

# Default values
TMUX_LEVEL="window"
BASE_BRANCH=""
FEATURES=""
SESSION_NAME=""  # Will be set to project name if not specified

# Arrays to track created worktrees for state file
CREATED_FEATURES=()
CREATED_BRANCHES=()
CREATED_WORKTREE_PATHS=()

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

# Show usage
usage() {
    cat << EOF
Usage: $0 --features "<feature1> <feature2> ..." [OPTIONS]

Create parallel development environments with tmux, git worktrees, and Claude Code.

Required:
  --features "<features>"    Space-separated list of feature names

Options:
  --tmux-level <level>       tmux organization level: session, window, or pane (default: window)
  --base-branch <branch>     Base branch for worktrees (default: current branch)
  --session-name <name>      tmux session name (default: project directory name)
  -h, --help                 Show this help message

Examples:
  $0 --features "login signup dashboard"
  $0 --features "auth api" --tmux-level pane
  $0 --features "feature1 feature2" --base-branch main --tmux-level session
EOF
    exit 1
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --features)
                FEATURES="$2"
                shift 2
                ;;
            --tmux-level)
                TMUX_LEVEL="$2"
                shift 2
                ;;
            --base-branch)
                BASE_BRANCH="$2"
                shift 2
                ;;
            --session-name)
                SESSION_NAME="$2"
                shift 2
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

    # Validate required arguments
    if [[ -z "$FEATURES" ]]; then
        print_error "Features are required"
        usage
    fi

    # Validate tmux level
    if [[ ! "$TMUX_LEVEL" =~ ^(session|window|pane)$ ]]; then
        print_error "Invalid tmux level: $TMUX_LEVEL. Must be session, window, or pane"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check tmux
    if ! command -v tmux &> /dev/null; then
        print_error "tmux is not installed"
        echo "Install tmux:"
        echo "  macOS:  brew install tmux"
        echo "  Ubuntu: sudo apt install tmux"
        echo "  Fedora: sudo dnf install tmux"
        exit 1
    fi

    # Check git
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi

    # Check if in git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        print_error "Not in a git repository"
        exit 1
    fi

    # Check claude command
    if ! command -v claude &> /dev/null; then
        print_warning "claude command not found. Claude Code will not be auto-started."
    fi

    print_success "All prerequisites checked"
}

# Get base branch
get_base_branch() {
    if [[ -z "$BASE_BRANCH" ]]; then
        BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    fi
    print_info "Using base branch: $BASE_BRANCH"
}

# Get session name (default to project directory name)
get_session_name() {
    if [[ -z "$SESSION_NAME" ]]; then
        local git_root=$(git rev-parse --show-toplevel)
        SESSION_NAME=$(basename "$git_root")
    fi
    print_info "Using session name: $SESSION_NAME"
}

# Sanitize feature name for git branch
sanitize_feature_name() {
    local name="$1"
    # Replace spaces and special characters with hyphens
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Get absolute path (cross-platform)
get_absolute_path() {
    local path="$1"
    if [[ -d "$path" ]]; then
        # Use cd && pwd for reliable absolute path resolution
        (cd "$path" && pwd)
    else
        # For non-existent paths, resolve the parent directory and append the basename
        local parent_dir=$(dirname "$path")
        local base_name=$(basename "$path")
        if [[ -d "$parent_dir" ]]; then
            echo "$(cd "$parent_dir" && pwd)/$base_name"
        else
            # Fallback: use Python for path resolution
            python3 -c "import os; print(os.path.abspath('$path'))" 2>/dev/null || \
            realpath -m "$path" 2>/dev/null || \
            echo "$path"
        fi
    fi
}

# Create git worktree for a feature
# Sets LAST_WORKTREE_PATH global variable with the created path
# All log messages go to stderr to avoid polluting the return value
# Also records the created worktree info to global arrays for state file
create_worktree() {
    local feature="$1"
    local sanitized=$(sanitize_feature_name "$feature")
    local branch_name="feature/$sanitized"

    # Get the current project directory name
    local git_root=$(git rev-parse --show-toplevel)
    local project_name=$(basename "$git_root")

    # Create worktree path: ../{project_name}-{feature_name}
    # This keeps worktrees at the same level as the main project, avoiding conflicts
    local worktree_path="../${project_name}-${sanitized}"

    print_info "Creating worktree for: $feature"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        print_warning "Worktree already exists at $worktree_path, reusing..."
    else
        # Check if branch exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            print_info "Branch $branch_name already exists, using it..."
            git worktree add "$worktree_path" "$branch_name"
        else
            print_info "Creating new branch $branch_name..."
            git worktree add -b "$branch_name" "$worktree_path" "$BASE_BRANCH"
        fi
        print_success "Worktree created at $worktree_path"
    fi

    # Get absolute path for state file
    local abs_worktree_path=$(get_absolute_path "$worktree_path")

    # Record to global arrays for state file
    CREATED_FEATURES+=("$sanitized")
    CREATED_BRANCHES+=("$branch_name")
    CREATED_WORKTREE_PATHS+=("$abs_worktree_path")

    # Set global variable for caller (avoid subshell issue)
    LAST_WORKTREE_PATH="$worktree_path"
}

# Create tmux session level environments
create_tmux_sessions() {
    local features=($FEATURES)

    print_info "Creating tmux sessions for each feature..."

    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        local session_name="$sanitized"
        create_worktree "$feature"
        local worktree_path="$LAST_WORKTREE_PATH"
        local abs_worktree_path=$(get_absolute_path "$worktree_path")

        # Check if session already exists
        if tmux has-session -t "$session_name" 2>/dev/null; then
            print_warning "Session $session_name already exists, skipping..."
            continue
        fi

        # Create new session
        tmux new-session -d -s "$session_name" -c "$abs_worktree_path"

        # Start Claude Code if available
        if command -v claude &> /dev/null; then
            tmux send-keys -t "$session_name" "claude" Enter
        fi

        print_success "Created session: $session_name"
    done

    echo ""
    print_success "All sessions created!"
    echo ""
    echo "Navigation:"
    echo "  List sessions:    tmux list-sessions"
    echo "  Attach session:   tmux attach -t <session-name>"
    echo "  Switch session:   Ctrl+b s (in tmux)"
    echo ""
    echo "Created sessions:"
    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        echo "  - $sanitized"
    done
}

# Create tmux window level environments
create_tmux_windows() {
    local features=($FEATURES)
    local first=true

    print_info "Creating tmux windows for each feature..."

    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        create_worktree "$feature"
        local worktree_path="$LAST_WORKTREE_PATH"
        local abs_worktree_path=$(get_absolute_path "$worktree_path")

        if $first; then
            # Create new session with first window
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                print_warning "Session $SESSION_NAME already exists, adding windows..."
            else
                tmux new-session -d -s "$SESSION_NAME" -n "$sanitized" -c "$abs_worktree_path"

                # Start Claude Code if available
                if command -v claude &> /dev/null; then
                    tmux send-keys -t "$SESSION_NAME:$sanitized" "claude" Enter
                fi

                first=false
                print_success "Created window: $sanitized (in session $SESSION_NAME)"
                continue
            fi
        fi

        # Create new window
        tmux new-window -t "$SESSION_NAME" -n "$sanitized" -c "$abs_worktree_path"

        # Start Claude Code if available
        if command -v claude &> /dev/null; then
            tmux send-keys -t "$SESSION_NAME:$sanitized" "claude" Enter
        fi

        print_success "Created window: $sanitized"
    done

    echo ""
    print_success "All windows created in session: $SESSION_NAME"
    echo ""
    echo "Navigation:"
    echo "  Attach session:   tmux attach -t $SESSION_NAME"
    echo "  Next window:      Ctrl+b n"
    echo "  Previous window:  Ctrl+b p"
    echo "  Select window:    Ctrl+b <number>"
    echo "  List windows:     Ctrl+b w"
    echo ""
    echo "Created windows:"
    local i=0
    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        echo "  $i: $sanitized"
        i=$((i + 1))
    done
}

# Create tmux pane level environments
create_tmux_panes() {
    local features=($FEATURES)
    local first=true
    local pane_count=0

    print_info "Creating tmux panes for each feature..."

    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        create_worktree "$feature"
        local worktree_path="$LAST_WORKTREE_PATH"
        local abs_worktree_path=$(get_absolute_path "$worktree_path")

        if $first; then
            # Create new session with first pane
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                print_warning "Session $SESSION_NAME already exists, adding panes..."
                # Split existing pane vertically (side by side)
                tmux split-window -h -t "$SESSION_NAME" -c "$abs_worktree_path"
            else
                tmux new-session -d -s "$SESSION_NAME" -c "$abs_worktree_path"
            fi

            # Start Claude Code if available
            if command -v claude &> /dev/null; then
                tmux send-keys -t "$SESSION_NAME" "claude" Enter
            fi

            first=false
            print_success "Created pane for: $sanitized"
            pane_count=$((pane_count + 1))
            continue
        fi

        # Split current pane vertically (side by side)
        tmux split-window -h -t "$SESSION_NAME" -c "$abs_worktree_path"

        # Rebalance panes
        tmux select-layout -t "$SESSION_NAME" tiled

        # Start Claude Code if available
        if command -v claude &> /dev/null; then
            tmux send-keys -t "$SESSION_NAME" "claude" Enter
        fi

        print_success "Created pane for: $sanitized"
        pane_count=$((pane_count + 1))
    done

    # Final layout adjustment
    tmux select-layout -t "$SESSION_NAME" tiled

    echo ""
    print_success "All panes created in session: $SESSION_NAME"
    echo ""
    echo "Navigation:"
    echo "  Attach session:   tmux attach -t $SESSION_NAME"
    echo "  Cycle panes:      Ctrl+b o"
    echo "  Arrow navigation: Ctrl+b <arrow>"
    echo "  Zoom pane:        Ctrl+b z"
    echo ""
    echo "Created $pane_count panes for features:"
    for feature in "${features[@]}"; do
        local sanitized=$(sanitize_feature_name "$feature")
        echo "  - $sanitized"
    done
}

# Save state file for merge command
save_state_file() {
    local git_root=$(git rev-parse --show-toplevel)
    local state_file_path="$git_root/$STATE_FILE"
    local created_at=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S")

    print_info "Saving state file: $state_file_path"

    cat > "$state_file_path" << EOF
---
base_branch: $BASE_BRANCH
tmux_level: $TMUX_LEVEL
session_name: $SESSION_NAME
created_at: $created_at
features:
EOF

    # Add each feature's info
    for i in "${!CREATED_FEATURES[@]}"; do
        cat >> "$state_file_path" << EOF
  - name: ${CREATED_FEATURES[$i]}
    branch: ${CREATED_BRANCHES[$i]}
    worktree_path: ${CREATED_WORKTREE_PATHS[$i]}
EOF
    done

    cat >> "$state_file_path" << 'EOF'
---

# Worktree Split State

This file tracks the state of parallel development environments created by `tmux-worktree-split`.

**DO NOT delete this file manually** - it will be automatically removed when you run `tmux-worktree-merge`.

## What this file is for

- Records which features were split from which base branch
- Tracks worktree locations and branch names
- Enables the merge command to clean up properly

## Next steps

1. Work on your features in the separate tmux windows/sessions
2. Commit your changes in each worktree
3. When ready to merge, run `/tmux-worktree-merge` in any of the worktrees
EOF

    print_success "State file saved"

    # Copy state file to each worktree
    print_info "Copying state file to worktrees..."
    for worktree_path in "${CREATED_WORKTREE_PATHS[@]}"; do
        if [[ -d "$worktree_path" ]]; then
            cp "$state_file_path" "$worktree_path/$STATE_FILE"
            print_success "Copied to: $worktree_path"
        fi
    done
}

# Main function
main() {
    echo ""
    echo "=========================================="
    echo "  tmux-worktree-split"
    echo "=========================================="
    echo ""

    parse_args "$@"
    check_prerequisites
    get_base_branch
    get_session_name

    echo ""
    print_info "Features: $FEATURES"
    print_info "tmux level: $TMUX_LEVEL"
    print_info "Base branch: $BASE_BRANCH"
    print_info "Session name: $SESSION_NAME"
    echo ""

    case $TMUX_LEVEL in
        session)
            create_tmux_sessions
            ;;
        window)
            create_tmux_windows
            ;;
        pane)
            create_tmux_panes
            ;;
    esac

    # Save state file for merge command
    echo ""
    save_state_file

    echo ""
    echo "=========================================="
    echo "  Setup Complete!"
    echo "=========================================="
    echo ""

    # Show how to attach
    if [[ "$TMUX_LEVEL" == "session" ]]; then
        local features=($FEATURES)
        local first_feature=$(sanitize_feature_name "${features[0]}")
        echo "To start working, run:"
        echo "  tmux attach -t $first_feature"
    else
        echo "To start working, run:"
        echo "  tmux attach -t $SESSION_NAME"
    fi
    echo ""
    echo "When ready to merge, run: /tmux-worktree-merge"
    echo ""
}

# Run main
main "$@"
