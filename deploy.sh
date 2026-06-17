#!/usr/bin/env bash
# Apply the validated optimization to the LIVE plugin install.
#
# Auto-discovers EVERY skill file changed since the pristine baseline (no hardcoded list to go stale):
#   - existed at baseline -> overwrite ONLY if the target still matches pristine (never clobber upstream)
#   - new since baseline  -> create if absent
#
# SAFE BY DEFAULT: dry-run unless --apply. Backs up before overwriting. --force overrides the guards.
#
# Usage:
#   bash deploy.sh                  # dry-run against the auto-detected active install
#   bash deploy.sh --apply          # deploy (with per-file backup)
#   bash deploy.sh --cache <path>   # override the target install path
#   bash deploy.sh --apply --force  # also overwrite files that differ from known-pristine
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
[ -d "$CACHE/skills" ] || { echo "ERROR: no skills/ under '$CACHE'. Pass --cache <path>." >&2; exit 1; }

echo "Target : $CACHE"
echo "Mode   : $([ $APPLY -eq 1 ] && echo APPLY || echo 'DRY-RUN (pass --apply to write)')"
BACKUP="$SRCROOT/backups/$(date -u +%Y%m%dT%H%M%SZ)"
applied=0; skipped=0; warned=0

while IFS= read -r rel; do
  [ -z "$rel" ] && continue                     # rel = plugin/skills/...
  f="${rel#plugin/}"; tgt="$CACHE/$f"
  # Already deployed (target == optimized HEAD)?  Source from git blobs (LF-canonical).
  if [ -f "$tgt" ] && git -C "$SRCROOT" show "HEAD:$rel" | diff -q - "$tgt" >/dev/null 2>&1; then
    echo "  skip  already current: $f"; skipped=$((skipped+1)); continue
  fi
  if git -C "$SRCROOT" cat-file -e "$BASELINE_REF:$rel" 2>/dev/null; then
    kind="update"                               # existed at baseline -> modified file
    if [ ! -f "$tgt" ]; then echo "  WARN  expected-but-missing in install: $f — skip"; warned=$((warned+1)); continue; fi
    if [ $FORCE -eq 0 ] && ! git -C "$SRCROOT" show "$BASELINE_REF:$rel" | diff -q - "$tgt" >/dev/null 2>&1; then
      echo "  WARN  differs from known-pristine (upstream-changed?): $f — skip (use --force)"; warned=$((warned+1)); continue
    fi
  else
    kind="add"                                  # new since baseline
    if [ -f "$tgt" ] && [ $FORCE -eq 0 ]; then
      echo "  WARN  unexpected existing file: $f — skip (use --force)"; warned=$((warned+1)); continue
    fi
  fi
  if [ $APPLY -eq 1 ]; then
    [ -f "$tgt" ] && { mkdir -p "$BACKUP/$(dirname "$f")"; cp "$tgt" "$BACKUP/$f"; }
    mkdir -p "$(dirname "$tgt")"
    git -C "$SRCROOT" show "HEAD:$rel" > "$tgt"
    echo "  $([ "$kind" = add ] && echo ADDED || echo UPDATED) $f"
  else
    echo "  would $kind $f"
  fi
  applied=$((applied+1))
done < <(git -C "$SRCROOT" diff --name-only "$BASELINE_REF" HEAD -- plugin/skills)

echo ""
echo "Summary: $([ $APPLY -eq 1 ] && echo applied || echo would-apply)=$applied  skipped=$skipped  warned=$warned"
if [ $APPLY -eq 1 ] && [ $applied -gt 0 ]; then
  echo "Backup : $BACKUP"
  echo "Rollback: copy files back from that backup dir, or run /plugin update, or git show $BASELINE_REF."
  echo "Then run /clear so the smaller always-on block is re-injected."
elif [ $APPLY -eq 0 ]; then
  echo "DRY-RUN only — nothing written. Re-run with --apply to deploy."
fi
