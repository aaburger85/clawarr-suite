#!/usr/bin/env bash
# Create the GitHub fork repo (if absent) and push this fork to it.
# Needs GITHUB_TOKEN in the environment (or in ~/.hermes/.env).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

[ -n "${GITHUB_TOKEN:-}" ] || { . "$HOME/.hermes/.env" 2>/dev/null || true; }
: "${GITHUB_TOKEN:?GITHUB_TOKEN not set (add it to ~/.hermes/.env)}"

API=https://api.github.com
AUTH="Authorization: Bearer $GITHUB_TOKEN"
USER="$(curl -sf -H "$AUTH" "$API/user" | python3 -c 'import json,sys; print(json.load(sys.stdin)["login"])')"
REPO="${REPO_NAME:-clawarr-suite}"
echo "publish: account=$USER repo=$REPO"

if curl -sf -o /dev/null -H "$AUTH" "$API/repos/$USER/$REPO"; then
  echo "publish: repo already exists"
else
  echo "publish: creating public repo $USER/$REPO"
  curl -sf -o /dev/null -X POST -H "$AUTH" \
    -d "{\"name\":\"$REPO\",\"description\":\"Fork of omiron33/clawarr-suite, normalized so Hermes can install/update it\",\"private\":false}" \
    "$API/user/repos"
fi

git remote remove origin 2>/dev/null || true
git remote add origin "https://${USER}:${GITHUB_TOKEN}@github.com/${USER}/${REPO}.git"
git remote remove upstream 2>/dev/null || true
git remote add upstream https://github.com/omiron33/clawarr-suite.git

git push -u origin main
echo "publish: done -> https://github.com/$USER/$REPO"
