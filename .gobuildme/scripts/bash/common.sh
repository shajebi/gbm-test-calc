#!/usr/bin/env bash
# Purpose : Share reusable helpers across all GoBuildMe Bash scripts.
# Why     : Centralizes branch detection, repo discovery, and file helpers so
#           command wrappers stay focused on their single responsibility.
# How     : Defines utility functions that infer project state (git, features,
#           specs) and provide consistent output to callers.

# -----------------------------
# Repository context helpers
# -----------------------------

# Get repository root, with fallback for non-git repositories.
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return
    fi

    # Fall back to walking up from the script location until we find a marker
    local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dir="$script_dir"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" || -f "$dir/pyproject.toml" || -d "$dir/.gobuildme" ]]; then
            echo "$dir"
            return
        fi
        dir="$(dirname "$dir")"
    done

    # Last resort: script directory
    echo "$script_dir"
}

# Get current branch, with fallback for non-git repositories.
get_current_branch() {
    # First check if SPECIFY_FEATURE environment variable is set
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi
    
    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi
    
    # For non-git repos, try to find the most recently modified feature directory
    local repo_root=$(get_repo_root)
    # Use hidden .gobuildme/specs exclusively because public specs are legacy.
    local specs_dir="$repo_root/.gobuildme/specs"

    if [[ -d "$specs_dir" ]]; then
        # Find the most recently modified directory (no numbering assumption)
        local latest_feature=""
        local latest_time=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                # Skip system directories
                if [[ "$dirname" != ".*" ]]; then
                    # Get modification time (seconds since epoch)
                    local mod_time
                    if command -v stat >/dev/null 2>&1; then
                        # macOS/BSD stat
                        mod_time=$(stat -f "%m" "$dir" 2>/dev/null || echo "0")
                    else
                        # GNU stat (Linux)
                        mod_time=$(stat -c "%Y" "$dir" 2>/dev/null || echo "0")
                    fi

                    if [[ "$mod_time" -gt "$latest_time" ]]; then
                        latest_time=$mod_time
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi
    
    echo "main"  # Final fallback when no feature branch can be derived.
}

# Check if we have git available.
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output.
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    # Check if it's a meaningful feature branch (not main, master, develop, etc.)
    if [[ "$branch" =~ ^(main|master|develop|dev|staging|production|prod)$ ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named descriptively, like: feature-name or jira-123-feature-name" >&2
        return 1
    fi

    return 0
}

# Determine the specs root directory (hidden by default).
get_specs_root() { echo "$1/.gobuildme/specs"; }

# Normalize a slug to kebab-case lowercase.
# Converts underscores/spaces to hyphens, lowercases, preserves -- separator.
# Example: "MyEpic" → "myepic", "FrontEnd_UI" → "frontend-ui", "My Epic" → "my-epic"
normalize_slug() {
    local input="$1"
    local result
    # Step 1: Lowercase
    result=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    # Step 2: Preserve -- by replacing with placeholder
    result=$(echo "$result" | sed 's/--/__DOUBLE_DASH__/g')
    # Step 3: Replace underscores, spaces, and other non-alphanumeric with hyphens
    result=$(echo "$result" | sed 's/[^a-z0-9-]/-/g')
    # Step 4: Collapse multiple hyphens to single
    result=$(echo "$result" | sed 's/-\+/-/g')
    # Step 5: Restore -- separator
    result=$(echo "$result" | sed 's/__DOUBLE_DASH__/--/g')
    # Step 6: Trim leading/trailing hyphens
    result=$(echo "$result" | sed 's/^-//' | sed 's/-$//')
    echo "$result"
}

# Get feature directory, supporting both standalone and sliced epics.
# For sliced epics (branch contains "--"), resolves to specs/epics/<epic>/<slice>/
# For standalone features, resolves to specs/<branch>/
get_feature_dir() {
    local repo_root="$1"
    local branch="$2"
    local specs_root
    specs_root=$(get_specs_root "$repo_root")

    # Step 1: Parse branch for double-dash (epic/slice separator)
    if [[ "$branch" == *"--"* ]]; then
        local epic_part="${branch%%--*}"    # Everything before first --
        local slice_part="${branch#*--}"    # Everything after first --
        local epic=$(normalize_slug "$epic_part")
        local slice=$(normalize_slug "$slice_part")

        # Step 2: Check registry first (canonical source of truth)
        local registry="$specs_root/epics/$epic/slice-registry.yaml"
        if [[ -f "$registry" ]]; then
            # Verify slice exists in registry (anchored match to avoid substrings)
            if grep -qE "^[[:space:]]*slice_name:[[:space:]]*${slice}$" "$registry" 2>/dev/null; then
                echo "$specs_root/epics/$epic/$slice"
                return 0
            fi
        fi

        # Step 3: Fallback to directory check
        if [[ -d "$specs_root/epics/$epic/$slice" ]]; then
            echo "$specs_root/epics/$epic/$slice"
            return 0
        fi

        # Step 4: No registry/directory found - return expected path for creation
        # NOTE: This is normal during slice creation (registry created by /gbm.request)
        # Return exit 0 so callers can proceed with directory creation
        echo "$specs_root/epics/$epic/$slice"
        return 0
    fi

    # Step 5: Standalone feature (no -- in branch)
    echo "$specs_root/$branch"
    return 0
}

# Get all valid feature directories (standalone + sliced).
# Returns paths to all feature directories for spec enumeration.
#
# USAGE:
#   source common.sh
#   REPO_ROOT=$(get_repo_root)
#   for feature_dir in $(get_all_feature_dirs "$REPO_ROOT"); do
#       echo "Processing: $feature_dir"
#   done
#
# RETURNS:
#   - Standalone features: .gobuildme/specs/<feature>/
#   - Sliced features: .gobuildme/specs/epics/<epic>/<slice>/
#
# NOTE: This is infrastructure for progress tracking, telemetry, CI status, etc.
#       If no scripts currently call it, that's intentional - it's available for future use.
get_all_feature_dirs() {
    local repo_root="$1"
    local specs_root
    specs_root=$(get_specs_root "$repo_root")

    # Standalone features: specs/<feature>/
    for d in "$specs_root"/*/; do
        if [[ -d "$d" ]]; then
            local dirname
            dirname=$(basename "$d")
            # Exclude epics directory (it contains sliced features, not standalone)
            if [[ "$dirname" != "epics" ]]; then
                echo "$d"
            fi
        fi
    done

    # Sliced features: specs/epics/<epic>/<slice>/
    if [[ -d "$specs_root/epics" ]]; then
        for epic_dir in "$specs_root/epics"/*/; do
            if [[ -d "$epic_dir" ]]; then
                for slice_dir in "$epic_dir"*/; do
                    if [[ -d "$slice_dir" ]]; then
                        local slice_name
                        slice_name=$(basename "$slice_dir")
                        # Exclude registry file (not a directory, but glob might catch it)
                        if [[ "$slice_name" != "slice-registry.yaml" ]]; then
                            echo "$slice_dir"
                        fi
                    fi
                done
            fi
        done
    fi
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"
    
    if has_git; then
        has_git_repo="true"
    fi
    
    local feature_dir=$(get_feature_dir "$repo_root" "$current_branch")
    
    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
REQUEST_FILE='$feature_dir/request.md'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
        QUICKSTART='$feature_dir/quickstart.md'
        CONTRACTS_DIR='$feature_dir/contracts'
        PRD='$feature_dir/prd.md'
EOF
}

# Lightweight status helpers used by setup commands to report readiness.
check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
