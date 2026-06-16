#!/usr/bin/env bash
# Apply the validated optimization to the LIVE plugin install.
# Nothing here runs automatically — you invoke it deliberately.
# RE-RUN after any `/plugin update` (updates overwrite the plugin cache).
#
# Usage:  bash deploy.sh            # uses the default active 5.5.0 cache path
#         bash deploy.sh <path>     # target a different install path (e.g. after a version bump)
set -euo pipefail

CACHE="${1:-$HOME/.claude/plugins/cache/superpowers-extended-cc-marketplace/superpowers-extended-cc/5.5.0}"
SRC="$(cd "$(dirname "$0")" && pwd)/plugin"

if [ ! -d "$CACHE/skills" ]; then
  echo "ERROR: no skills/ under '$CACHE'. Pass the correct install path as arg 1." >&2
  echo "Hint: ls ~/.claude/plugins/cache/superpowers-extended-cc-marketplace/superpowers-extended-cc/" >&2
  exit 1
fi

files=(
  skills/using-superpowers/SKILL.md            # Tier-0 always-on rewrite (-31.2% tokens)
  skills/brainstorming/SKILL.md                # CSO description
  skills/checking-gates/SKILL.md               # CSO description
  skills/finishing-a-development-branch/SKILL.md
  skills/receiving-code-review/SKILL.md
  skills/specifying-gates/SKILL.md
  skills/using-git-worktrees/SKILL.md
  skills/verification-before-completion/SKILL.md
)

echo "Deploying 8 optimized files -> $CACHE"
for f in "${files[@]}"; do cp "$SRC/$f" "$CACHE/$f"; echo "  deployed $f"; done
echo "Done. Run /clear (or restart Claude Code) so the smaller always-on block is re-injected."
echo "Rollback: re-run \`/plugin update\` (restores upstream) or copy the files back from git baseline f647c54."
