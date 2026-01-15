#!/usr/bin/env bash
# Purpose : Drive the `/request` command by preparing branch context and files.
# Why     : Keeps Spec-Driven requests consistent—establishing feature folders,
#           templated request docs, and machine-friendly output consumed by
#           downstream commands.
# How     : Parses overrides, normalizes the request narrative, ensures the
#           feature workspace exists, and emits structured metadata JSON/text.
set -euo pipefail

JSON_MODE=false
ARGS=()

# Parse CLI arguments to decide between JSON output and positional text payload.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--json] <request_description>"
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

RAW_REQUEST="${ARGS[*]:-}"
if [[ -z "$RAW_REQUEST" ]]; then
  echo "Usage: $0 [--json] <request_description>" >&2
  exit 1
fi

# Support inline slug/branch overrides while preserving the human narrative.
CUSTOM_SLUG=""
TRIMMED_LINES=()
while IFS= read -r line; do
  if [[ $line =~ ^[[:space:]]*(slug|branch)[[:space:]]*[:=][[:space:]]*(.+)$ ]]; then
    CUSTOM_SLUG="${BASH_REMATCH[2]}"
    CUSTOM_SLUG="${CUSTOM_SLUG%\"}"
    CUSTOM_SLUG="${CUSTOM_SLUG#\"}"
    CUSTOM_SLUG="${CUSTOM_SLUG%\'}"
    CUSTOM_SLUG="${CUSTOM_SLUG#\'}"
    continue
  fi
  TRIMMED_LINES+=("$line")
done <<< "${RAW_REQUEST//$'\r'/}"  # normalize CRLF if present

REQUEST_DESCRIPTION=$(printf '%s\n' "${TRIMMED_LINES[@]}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/^ //; s/ $//')

if [[ -z "$REQUEST_DESCRIPTION" ]]; then
  REQUEST_DESCRIPTION="$RAW_REQUEST"
fi

CUSTOM_SLUG=$(echo "$CUSTOM_SLUG" | sed 's/^ *//; s/ *$//')

# Normalize / to -- for epic/slice format (backward compatibility)
if [[ "$CUSTOM_SLUG" == *"/"* ]]; then
  ORIGINAL_SLUG="$CUSTOM_SLUG"
  CUSTOM_SLUG=$(echo "$CUSTOM_SLUG" | sed 's|/|--|g')
  echo "📝 Slug normalized: $ORIGINAL_SLUG → $CUSTOM_SLUG" >&2
fi

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Resolve repository context for feature branch creation.
REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

# Determine current branch and whether we need to create/switch to a new feature branch.
BRANCH=$(get_current_branch)
NEEDS_NEW_BRANCH=false

# Always branch off protected branches.
if [[ "$BRANCH" =~ ^(main|master|develop|dev|staging|production|prod)$ ]]; then
  NEEDS_NEW_BRANCH=true
fi

# If user explicitly provided a slug, honor it by creating/switching unless already on it.
# Normalize both to lowercase for comparison (create-new-feature normalizes slugs)
if [[ -n "$CUSTOM_SLUG" ]]; then
  CUSTOM_SLUG_LOWER=$(echo "$CUSTOM_SLUG" | tr '[:upper:]' '[:lower:]')
  BRANCH_LOWER=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]')
  if [[ "$BRANCH_LOWER" != "$CUSTOM_SLUG_LOWER" ]]; then
    NEEDS_NEW_BRANCH=true
  fi
fi

# If current branch already has a request.md, create a new branch unless user explicitly reuses it.
if [[ "$NEEDS_NEW_BRANCH" == "false" ]] && [[ -z "$CUSTOM_SLUG" ]]; then
  CURRENT_FEATURE_DIR=$(get_feature_dir "$REPO_ROOT" "$BRANCH")
  if [[ -f "$CURRENT_FEATURE_DIR/request.md" ]]; then
    echo "⚠️  Existing request.md found for branch '$BRANCH' - creating a new feature branch to avoid mixing requests." >&2
    echo "ℹ️  If you intended to reuse this branch, re-run with: slug: $BRANCH" >&2
    NEEDS_NEW_BRANCH=true
  fi
fi

if [[ "$NEEDS_NEW_BRANCH" == "true" ]]; then
  echo "ℹ️  Creating feature branch from '$BRANCH'..." >&2
  if [[ -n "$CUSTOM_SLUG" ]]; then
    out_json=$("$SCRIPT_DIR/create-new-feature.sh" --json --slug "$CUSTOM_SLUG" "$REQUEST_DESCRIPTION") || {
      echo "Error: create-new-feature.sh failed." >&2
      exit 1
    }
  else
    out_json=$("$SCRIPT_DIR/create-new-feature.sh" --json "$REQUEST_DESCRIPTION") || {
      echo "Error: create-new-feature.sh failed." >&2
      exit 1
    }
  fi
  NEW_BRANCH=$(printf '%s' "$out_json" | sed -n 's/.*"BRANCH_NAME":"\([^"]*\)".*/\1/p')

  if [[ -z "$NEW_BRANCH" ]]; then
    echo "Error: Failed to parse new branch name from create-new-feature output." >&2
    exit 1
  fi

  # Only verify/checkout if we're in a git repo
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git rev-parse --verify "$NEW_BRANCH" >/dev/null 2>&1; then
      echo "Error: New branch '$NEW_BRANCH' not found after creation." >&2
      exit 1
    fi

    if ! git checkout "$NEW_BRANCH" >/dev/null 2>&1; then
      echo "Error: Failed to switch to new branch '$NEW_BRANCH'." >&2
      exit 1
    fi
    echo "✅ Switched to feature branch: $NEW_BRANCH" >&2
  else
    echo "ℹ️  Non-git mode: using feature name '$NEW_BRANCH'" >&2
  fi

  BRANCH="$NEW_BRANCH"
fi

FEATURE_DIR=$(get_feature_dir "$REPO_ROOT" "$BRANCH")
mkdir -p "$FEATURE_DIR"

# Seed the request document from templates when needed.
REQUEST_FILE="$FEATURE_DIR/request.md"
if [[ ! -f "$REQUEST_FILE" ]]; then
  TPL="$REPO_ROOT/.gobuildme/templates/request-template.md"
  [[ -f "$TPL" ]] || TPL="$REPO_ROOT/templates/request-template.md"
  if [[ -f "$TPL" ]]; then cp "$TPL" "$REQUEST_FILE"; else echo -e "# Request\n\n> Describe the user request, context, and open questions." > "$REQUEST_FILE"; fi
fi

# Note: spec.md should only be created by /specify command, not /request
SPEC_FILE="$FEATURE_DIR/spec.md"

if $JSON_MODE; then
  # Downstream commands prefer JSON so they can fetch absolute paths quickly.
  printf '{"BRANCH_NAME":"%s","REQUEST_FILE":"%s","SPEC_FILE":"%s","FEATURE_DIR":"%s"}\n' \
    "$BRANCH" "$REQUEST_FILE" "$SPEC_FILE" "$FEATURE_DIR"
else
  # Human-friendly output keeps shell users aware of generated resources.
  echo "BRANCH_NAME: $BRANCH"
  echo "REQUEST_FILE: $REQUEST_FILE"
  echo "SPEC_FILE: $SPEC_FILE"
  echo "FEATURE_DIR: $FEATURE_DIR"
fi

# Record metadata for this artifact (optional, non-blocking)
# Note: User Goals extraction will happen after AI agent writes request content
if command -v python3 >/dev/null 2>&1; then
  METADATA_SCRIPT="$SCRIPT_DIR/../record-metadata.py"
  if [[ -f "$METADATA_SCRIPT" ]]; then
    python3 "$METADATA_SCRIPT" \
      --feature-name "$BRANCH" \
      --command "request" \
      --artifact-path "$REQUEST_FILE" \
      --repo-root "$REPO_ROOT" \
      >/dev/null 2>&1 || true
  fi
fi
