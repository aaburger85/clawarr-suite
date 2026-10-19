#!/usr/bin/env bash
# Pull upstream main wholesale into the fork, re-apply the normalizer, stage the result.
# Wholesale copy + deterministic re-normalize => never a merge conflict.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILL="$ROOT/skills/clawarr-suite"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/omiron33/clawarr-suite.git}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "sync: fetching upstream main..."
git clone -q --depth 1 "$UPSTREAM_URL" "$TMP/up"

echo "sync: replacing skill content with upstream..."
rsync -a --delete --exclude '.git' "$TMP/up/" "$SKILL/"
rm -f "$SKILL/.gitignore" "$SKILL/LICENSE"

echo "sync: restoring ClawHub-only artifacts..."
cp -a "$ROOT/vendor/clawhub-artifacts/." "$SKILL/"

"$ROOT/normalize.sh"

if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" add -A
  echo "sync: staged changes vs HEAD:"
  git -C "$ROOT" diff --cached --stat
else
  echo "sync: (no git repo yet - run publish.sh)"
fi
