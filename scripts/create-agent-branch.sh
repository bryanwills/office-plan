#!/usr/bin/env bash
# create-agent-branch.sh — standard "handoff point" for every AI agent that
# works on a shared repo. Solves the agents-drift problem: no more uncommitted
# work sitting invisible on one machine, discovered only weeks later.
#
# Usage:
#   bash create-agent-branch.sh <agent-name> [commit-message]
#
# Example (Hermes session on the MacBook Pro):
#   bash scripts/create-agent-branch.sh hermes "honest state: honcho stack uncommitted, work on NUC paused"
#
# What it does:
#   1. Stash any uncommitted changes (tracked + untracked) as an audit trail
#   2. Create branch: <agent>/<slug>-YYYY-MM-DD
#   3. Commit the work with an AGENT-ORIGIN trailer (agent, machine, timestamp)
#   4. Push to origin (safe — nothing touches main)
#   5. Print a handoff block to paste into PROJECT_STATE.md
#
# Design rule: an agent NEVER commits directly to main in a shared repo.
# main is only filled by human-merged PRs.

set -euo pipefail

AGENT="${1:?usage: create-agent-branch.sh <agent-name> [commit-message]}"
MSG="${2:-handoff from ${AGENT}}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
SLUG="$(echo "$AGENT" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
BRANCH="${SLUG}/$(echo "$AGENT" | tr '[:upper:]' '[:lower:]')-$(date +%Y-%m-%d)"
DATE="$(date '+%Y-%m-%d %H:%M %Z')"
MACHINE="$(hostname -s 2>/dev/null || hostname)"

echo "==> Agent handoff: ${AGENT}"
echo "    Repo:    $REPO_ROOT"
echo "    Branch:  $BRANCH"
echo "    Machine: $MACHINE"

# --- 0. Safety: never run this on main with dirty changes we can't trace -----
if git branch --show-current | grep -q '^main$'; then
  echo "==> On main. Creating branch ${BRANCH} first."
  git checkout -b "$BRANCH"
fi

# --- 1. Stash (audit trail, even if empty) ---------------------------------
STASH_OUT="$(git stash push -u -m "handoff-$(date +%Y%m%d-%H%M%S) ${AGENT}" 2>&1 || true)"
echo "    Stash:   ${STASH_OUT:-clean tree, nothing stashed}"

# --- 2. Stage everything and commit on the new branch -----------------------
git add -A -- ':!*.env' ':!.env.*' 2>/dev/null || git add -A
git -c user.name="${AGENT}" \
    -c user.email="${SLUG}@agents.local" \
    commit --allow-empty \
      -m "$MSG" \
      --trailer "AGENT-ORIGIN: ${AGENT} @ ${MACHINE} @ ${DATE}" \
      --trailer "SESSION-HANDOFF: true"

# --- 3. Push with upstream (idempotent: skip if remote branch exists) --------
git push -u origin "$BRANCH" \
  || { echo "!! Push failed — commit kept locally on ${BRANCH}."; exit 1; }

# --- 4. Handoff block for PROJECT_STATE.md -----------------------------------
cat <<HANDOFF

---
## HANDOFF BLOCK (paste into PROJECT_STATE.md §6 / §7)

- Agent:          ${AGENT}
- Machine:        ${MACHINE}
- Branch:         \`${BRANCH}\` (pushed to origin)
- Timestamp:      ${DATE}
- What was done:  $MSG
- Uncommitted work stashed/committed?  YES (see commit + push above)
HANDOFF

echo
echo "==> DONE. Next step: update PROJECT_STATE.md §6 (Immediate Priorities)"
echo "    with this branch name, then open a PR:  gh pr create --fill"
echo "    If work continues on another machine, START FROM THIS BRANCH."
