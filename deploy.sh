#!/usr/bin/env bash
# Apply the validated optimization to the LIVE plugin install.
#
# SAFE BY DEFAULT: this is a DRY-RUN unless you pass --apply. (An earlier version
# deployed on an empty arg — that footgun is fixed; nothing writes without --apply.)
#
# Usage:
#   bash deploy.sh                  # dry-run against the auto-detected active install
#   bash deploy.sh --apply          # actually deploy (with per-file backup)
#   bash deploy.sh --cache <path>   # override the target install path
#   bash deploy.sh --apply --force  # also overwrite files that differ from known-pristine
#                                   #   (e.g. an upstream-changed file on a newer version)
set -euo pipefail

APPLY=0; FORCE=0; CACHE=""
while [ $# -gt 0 ]; do
  case "${1:-}" in
    --apply) APPLY=1 ;;
    --force) FORCE=1 ;;
    --cache) shift; CACHE="${1:-}"; [ -z "$CACHE" ] && { echo "ERROR: --cache needs a path" >&2; exit 1; } ;;
    "") echo "ERROR: empty argument. Use --apply / --cache <path>." >&2; exit 1 ;;
    *) echo "ERROR: unknown argument '$1'" >&2; exit 1 ;;
  esac
  shift
done

SRCROOT="$(cd "$(dirname "$0")" && pwd)"
BASELINE_REF="f647c54"   # pristine v5.5.0 == upstream 26c74c8 (audit-verified)

# Resolve the ACTIVE install path (don't hard-pin a version that /plugin update can supersede).
if [ -z "$CACHE" ]; then
  IP="$HOME/.claude/plugins/installed_plugins.json"
  if command -v jq >/dev/null 2>&1 && [ -f "$IP" ]; then
    raw=$(jq -r '.["superpowers-extended-cc@superpowers-extended-cc-marketplace"][0].installPath // empty' "$IP" 2>/dev/null || true)
    [ -n "$raw" ] && CACHE=$(printf '%s' "$raw" | sed 's#\\#/#g')
  fi
  [ -z "$CACHE" ] && CACHE="$HOME/.claude/plugins/cache/superpowers-extended-cc-marketplace/superpowers-extended-cc/5.5.0"
fi
if [ ! -d "$CACHE/skills" ]; then
  echo "ERROR: no skills/ under '$CACHE'. Pass --cache <path>." >&2; exit 1
fi

files=(
  skills/using-superpowers/SKILL.md            # Tier-0 always-on rewrite (-31.2% tokens)
  skills/brainstorming/SKILL.md                # CSO description
  skills/checking-gates/SKILL.md
  skills/finishing-a-development-branch/SKILL.md
  skills/receiving-code-review/SKILL.md
  skills/specifying-gates/SKILL.md
  skills/using-git-worktrees/SKILL.md
  skills/verification-before-completion/SKILL.md
)

echo "Target : $CACHE"
echo "Mode   : $([ $APPLY -eq 1 ] && echo APPLY || echo 'DRY-RUN (pass --apply to write)')"
BACKUP="$SRCROOT/backups/$(date -u +%Y%m%dT%H%M%SZ)"
applied=0; skipped=0; warned=0

for f in "${files[@]}"; do
  tgt="$CACHE/$f"
  [ -f "$tgt" ] || { echo "  WARN  not in install: $f (skip)"; warned=$((warned+1)); continue; }
  # Source content from git blobs (LF-canonical) — avoids CRLF contamination from the working tree.
  if git -C "$SRCROOT" show "HEAD:plugin/$f" | diff -q - "$tgt" >/dev/null 2>&1; then
    echo "  skip  already optimized: $f"; skipped=$((skipped+1)); continue
  fi
  if ! git -C "$SRCROOT" show "$BASELINE_REF:plugin/$f" | diff -q - "$tgt" >/dev/null 2>&1; then
    if [ $FORCE -eq 0 ]; then
      echo "  WARN  target differs from known-pristine (upstream-changed?): $f — skip (use --force)"; warned=$((warned+1)); continue
    fi
  fi
  if [ $APPLY -eq 1 ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"; cp "$tgt" "$BACKUP/$f"
    git -C "$SRCROOT" show "HEAD:plugin/$f" > "$tgt"
    echo "  APPLIED $f"
  else
    echo "  would deploy $f"
  fi
  applied=$((applied+1))
done

echo ""
echo "Summary: $([ $APPLY -eq 1 ] && echo applied || echo would-apply)=$applied  skipped=$skipped  warned=$warned"
if [ $APPLY -eq 1 ] && [ $applied -gt 0 ]; then
  echo "Backup : $BACKUP"
  echo "Rollback: copy files back from that backup dir, or run /plugin update, or git show $BASELINE_REF."
  echo "Then run /clear so the smaller always-on block is re-injected."
elif [ $APPLY -eq 0 ]; then
  echo "DRY-RUN only — nothing written. Re-run with --apply to deploy."
fi
