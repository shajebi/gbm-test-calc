#!/usr/bin/env bash
# Purpose : Run the preflight stack before executing `/push`.
# Why     : Ensures developers run the full battery of checks prior to opening
#           a pull request, catching issues locally.
# How     : Sequentially invokes format, lint, type, test, security, and branch
#           status scripts, aggregating their output for review.
set -euo pipefail

echo "== Pre-commit: format =="; .gobuildme/scripts/bash/run-format.sh || true
echo "== Lint =="; .gobuildme/scripts/bash/run-lint.sh || true
echo "== Type check =="; .gobuildme/scripts/bash/run-type-check.sh || true
echo "== Tests =="; .gobuildme/scripts/bash/run-tests.sh || true
echo "== Security =="; .gobuildme/scripts/bash/security-scan.sh || true
echo "== Branch status =="; .gobuildme/scripts/bash/branch-status.sh || true

# Advisory PRD presence (non-blocking)
if [ -f .gobuildme/scripts/bash/common.sh ]; then
  # shellcheck disable=SC1091
  source .gobuildme/scripts/bash/common.sh
  eval "$(get_feature_paths)"
  echo "== PRD status =="
  if [ -f "$PRD" ]; then
    echo "PRD found: $PRD"
  else
    echo "PRD not found for current feature ($FEATURE_DIR) — optional unless changing user behavior/commitments."
  fi
fi

echo "\nAll checks executed. Review outputs above; if clean, you're ready to push."
