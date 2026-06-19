#!/usr/bin/env bash
# Integration test for deploy.sh — proves its safety guarantees against a throwaway fixture install.
# The fixture is the pristine-baseline plugin tree: inherited files match upstream, new skills are absent.
# Needs the `pristine-baseline` tag (CI checks out with fetch-tags) and `git archive` + `tar`.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY="$SRC/deploy.sh"
PASS=0; FAIL=0
ok(){ printf '  PASS  %s\n' "$1"; PASS=$((PASS+1)); }
no(){ printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
CREATED_BACKUP=""
cleanup(){ rm -rf "$TMP"; [ -n "$CREATED_BACKUP" ] && rm -rf "$CREATED_BACKUP"; }
trap cleanup EXIT

# Only plugin/skills exists at baseline; the tier agents are new since baseline, so they are
# correctly absent from the fixture (they exercise deploy's "add" path).
git -C "$SRC" archive pristine-baseline plugin/skills | tar -x -C "$TMP"
CACHE="$TMP/plugin"
[ -d "$CACHE/skills" ] || { echo "fixture build failed (need the pristine-baseline tag)"; exit 1; }

echo "== deploy.sh integration test =="

# --- arg guards ---
bash "$DEPLOY" --cache --apply       >/dev/null 2>&1 && no "'--cache --apply' must be rejected" || ok "'--cache --apply' rejected (flag not swallowed)"
bash "$DEPLOY" --cache "$TMP/missing" >/dev/null 2>&1 && no "missing cache must be rejected"     || ok "missing cache dir rejected"

# --- dry-run: exit 0, announces DRY-RUN, plans an add, and writes NOTHING ---
snap(){ ( cd "$CACHE" && find . -type f | sort | xargs md5sum 2>/dev/null | md5sum ); }
before="$(snap)"
out="$(bash "$DEPLOY" --cache "$CACHE" 2>&1)"; rc=$?
[ "$rc" -eq 0 ]                                  && ok "dry-run exits 0" || no "dry-run exit=$rc"
grep -q "DRY-RUN" <<<"$out"                      && ok "dry-run announces DRY-RUN" || no "no DRY-RUN banner"
grep -q "would add agents/sp-deep.md" <<<"$out"  && ok "dry-run plans to add a new agent" || no "missing add plan"
[ "$before" = "$(snap)" ]                        && ok "dry-run wrote NOTHING" || no "dry-run mutated the install"

# --- --apply: an upstream-modified file must NOT be clobbered, while new files ARE added + a backup IS taken ---
victim="$CACHE/skills/brainstorming/SKILL.md"
printf '\nLOCAL UPSTREAM EDIT\n' >> "$victim"
vbefore="$(md5sum "$victim")"
aout="$(bash "$DEPLOY" --cache "$CACHE" --apply 2>&1)"
CREATED_BACKUP="$(sed -n 's/^Backup : //p' <<<"$aout")"
[ "$vbefore" = "$(md5sum "$victim")" ]           && ok "--apply did NOT clobber the upstream-modified file" || no "clobbered an upstream-modified file"
[ -f "$CACHE/agents/sp-deep.md" ]                && ok "--apply added a new agent" || no "new agent not added"
{ [ -n "$CREATED_BACKUP" ] && [ -d "$CREATED_BACKUP" ]; } && ok "--apply created a backup before writing" || no "no backup created"

echo ""
echo "deploy.sh: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
