#!/usr/bin/env bash
# Linux/macOS twin of push.bat. Same arguments, same behaviour.
#   ./push.sh "message"              commit and push
#   ./push.sh "message" v1.0.6       ...tag it, which builds and releases
#   ./push.sh "message" notag        ...commit and push without tagging
set -uo pipefail
cd "$(dirname "$0")" || exit 1

REPO="arnavaggarwal-dev/brackeys-ForReals"
REMOTE_URL="https://github.com/$REPO.git"
BRANCH="main"

MESSAGE="${1:-}"
TAG="${2:-}"

[ -z "$MESSAGE" ] && MESSAGE="work in progress - $(date '+%Y-%m-%d %H:%M')"

fail() { printf '\n[X] Failed. Nothing further was pushed.\n\n'; exit 1; }

if [ "${TAG,,}" = "notag" ]; then
    TAG="none"
elif [ -z "$TAG" ]; then
    last=$(git tag --list 'v*' --sort=-v:refname | head -1)
    [ -z "$last" ] && last="v0.0.0"
    IFS=. read -r maj min pat <<< "${last#v}"
    TAG="v$maj.$min.$((pat + 1))"
fi

printf '\n=== ForReals =============================================================\n'
printf '  branch  : %s\n' "$BRANCH"
printf '  message : %s\n' "$MESSAGE"
[ "$TAG" != "none" ] && printf '  tag     : %s  (builds every platform in CI and publishes a release)\n' "$TAG"
printf '==========================================================================\n\n'

git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "[X] Not a git repository. Run this from the project folder."; fail; }

git lfs version >/dev/null 2>&1 || {
    echo "[X] Git LFS is not installed. The builds folder cannot be pushed"
    echo "    without it - ForReals.exe alone is over GitHub's 100 MB limit."
    echo "    Arch: sudo pacman -S git-lfs && git lfs install"
    fail; }
git lfs install --local >/dev/null 2>&1

git remote get-url origin >/dev/null 2>&1 || {
    echo "[*] No 'origin' remote yet - pointing it at $REMOTE_URL"
    git remote add origin "$REMOTE_URL" || fail; }

echo "[*] Staging..."
git add -A || fail

if git diff --cached --quiet; then
    echo "[*] Nothing to commit - the tree is already clean."
else
    printf '\n'; git status --short; printf '\n'
    echo "[*] Committing..."
    git commit -m "$MESSAGE" || fail
fi

echo "[*] Pushing to $BRANCH (LFS objects make this the slow part)..."
git push -u origin "$BRANCH" || fail

if [ "$TAG" != "none" ]; then
    echo "[*] Tagging $TAG..."
    git tag -a "$TAG" -m "$MESSAGE" || {
        echo "[X] Could not create tag $TAG - does it already exist?"; fail; }
    git push origin "$TAG" || fail

    if ! command -v gh >/dev/null 2>&1; then
        echo "[!] gh CLI not found - the release is building, but this script"
        echo "    cannot wait for it."
        echo "    https://github.com/$REPO/actions"
    else
        echo "[*] Waiting for GitHub to export Windows, Linux, macOS, web, Android and iOS..."
        sleep 15
        RUNID=$(gh run list --repo "$REPO" --limit 1 --json databaseId --jq '.[0].databaseId')
        if [ -z "$RUNID" ]; then
            echo "[!] Could not find the workflow run. Check it by hand."
        elif ! gh run watch "$RUNID" --repo "$REPO" --exit-status --interval 20; then
            echo "[X] The release build failed. See:"
            echo "    https://github.com/$REPO/actions/runs/$RUNID"
            fail
        else
            echo "[+] Release $TAG published with every platform."
        fi
    fi
fi

printf '\n[+] Done.\n    https://github.com/%s\n\n' "$REPO"
