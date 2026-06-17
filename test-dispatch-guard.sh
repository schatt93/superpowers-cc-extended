#!/usr/bin/env bash
# Adversarial test battery for the model-routing enforcement hook.
# Feeds crafted Agent dispatches + transcript fixtures to the hook and asserts
# exit codes. Pure test harness — installs nothing, mutates nothing live.
#   exit 0 = ALLOW dispatch, exit 2 = BLOCK dispatch.
set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/plugin/hooks/examples/pre-agent-task-dispatch-validate.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0; FINDINGS=()

# meta(model, subtype, brief) -> a json:metadata fence (omit a field by passing "-")
fence() {
  local m="$1" s="$2" b="$3" parts=()
  [[ "$s" != "-" ]] && parts+=("\\\"subagentType\\\":\\\"$s\\\"")
  [[ "$m" != "-" ]] && parts+=("\\\"model\\\":\\\"$m\\\"")
  [[ "$b" != "-" ]] && parts+=("\\\"dispatchBrief\\\":\\\"$b\\\"")
  local IFS=,; echo "\`\`\`json:metadata\\n{${parts[*]}}\\n\`\`\`"
}
# transcript with one in_progress task carrying the given metadata fence
tx_inprogress() {
  local file="$1" meta="$2"
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"Demo task","description":"**Goal:** x.\\n\\n%s"}}]}}\n' "$meta" > "$file"
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"1","status":"in_progress"}}]}}\n' >> "$file"
}
run() { # run(label, expected_rc, dispatch_json, transcript_path, [env])
  local label="$1" exp="$2" disp="$3" tx="$4" envv="${5:-}"
  local rc
  rc=$(printf '%s' "$disp" | env $envv bash "$HOOK" >/dev/null 2>"$WORK/err"; echo $?)
  if [[ "$rc" == "$exp" ]]; then printf "  PASS  %-58s (rc=%s)\n" "$label" "$rc"; PASS=$((PASS+1))
  else printf "  FAIL  %-58s (got rc=%s, want %s)\n" "$label" "$rc" "$exp"; FAIL=$((FAIL+1)); fi
}
disp() { # disp(subtype, model, prompt)
  printf '{"tool_name":"Agent","tool_input":{"subagent_type":"%s","model":"%s","prompt":"%s"},"transcript_path":"%s"}' "$1" "$2" "$3" "$4"
}

echo "=== ADVERSARIAL: model-routing dispatch guard ==="

# 1. Happy path: everything matches -> ALLOW
tx_inprogress "$WORK/t1" "$(fence haiku general-purpose 'measure tokens')"
run "match: model+subtype+brief all correct" 0 "$(disp general-purpose haiku 'please measure tokens now' "$WORK/t1")" "$WORK/t1"

# 2. Model mismatch -> BLOCK
run "block: task wants haiku, dispatch sends opus" 2 "$(disp general-purpose opus 'please measure tokens now' "$WORK/t1")" "$WORK/t1"

# 3. Subagent-type mismatch -> BLOCK
run "block: task wants general-purpose, dispatch sends Explore" 2 "$(disp Explore haiku 'please measure tokens now' "$WORK/t1")" "$WORK/t1"

# 4. dispatchBrief substring missing -> BLOCK
run "block: prompt missing required brief substring" 2 "$(disp general-purpose haiku 'do something else' "$WORK/t1")" "$WORK/t1"

# 5. No metadata at all -> ALLOW (no requirement)
tx_inprogress "$WORK/t5" ""
run "allow: in_progress task has no metadata fence" 0 "$(disp general-purpose opus 'whatever' "$WORK/t5")" "$WORK/t5"

# 6. No in_progress task -> ALLOW
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"created only","description":"x"}}]}}\n' > "$WORK/t6"
run "allow: task created but never marked in_progress" 0 "$(disp general-purpose opus 'x' "$WORK/t6")" "$WORK/t6"

# 7. Non-Agent tool -> ALLOW
run "allow: tool is Bash, not Agent" 0 "$(printf '{"tool_name":"Bash","tool_input":{"command":"ls"},"transcript_path":"%s"}' "$WORK/t1")" "$WORK/t1"

# 8. Escape hatch -> ALLOW even on mismatch
run "allow: SUPERPOWERS_DISPATCH_GUARD=0 overrides a mismatch" 0 "$(disp general-purpose opus 'please measure tokens now' "$WORK/t1")" "$WORK/t1" "SUPERPOWERS_DISPATCH_GUARD=0"

# --- adversarial / break-it cases ---

# 9. Malformed metadata JSON -> should FAIL OPEN (allow), not crash
tx_inprogress "$WORK/t9" "\`\`\`json:metadata\\n{not valid json,,,}\\n\`\`\`"
run "fail-open: malformed metadata JSON does not crash/block" 0 "$(disp general-purpose opus 'x' "$WORK/t9")" "$WORK/t9"

# 10. Missing transcript file -> ALLOW (fail-open)
run "fail-open: transcript path does not exist" 0 "$(disp general-purpose opus 'x' "$WORK/does-not-exist")" "$WORK/does-not-exist"

# 11. BYPASS PROBE: mark task completed, then dispatch -> guard OFF (allow)
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"Demo","description":"x.\\n\\n%s"}}]}}\n' "$(fence haiku general-purpose 'brief')" > "$WORK/t11"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"1","status":"in_progress"}}]}}\n' >> "$WORK/t11"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"1","status":"completed"}}]}}\n' >> "$WORK/t11"
rc=$(printf '%s' "$(disp general-purpose opus 'x' "$WORK/t11")" | bash "$HOOK" >/dev/null 2>&1; echo $?)
if [[ "$rc" == 0 ]]; then echo "  PASS  bypass-probe: completed task -> no enforcement (rc=0)"; PASS=$((PASS+1)); FINDINGS+=("BYPASS: marking the task completed before dispatch disables the guard (rc=0). Expected design, but a real evasion path."); else echo "  NOTE  completed task still enforced (rc=$rc)"; fi

# 12. Agent OMITS model entirely (inherits default) but task requires haiku -> BLOCK
run "good: omitted model field is caught as mismatch (empty != haiku)" 2 "$(printf '{"tool_name":"Agent","tool_input":{"subagent_type":"general-purpose","prompt":"please measure tokens now"},"transcript_path":"%s"}' "$WORK/t1")" "$WORK/t1"

# 13. BRITTLENESS PROBE: case mismatch Haiku vs haiku -> BLOCK (exact string)
tx_inprogress "$WORK/t13" "$(fence Haiku general-purpose 'brief')"
rc=$(printf '%s' "$(disp general-purpose haiku 'brief here' "$WORK/t13")" | bash "$HOOK" >/dev/null 2>&1; echo $?)
if [[ "$rc" == 2 ]]; then echo "  PASS  brittleness-probe: 'Haiku' vs 'haiku' blocks (rc=2)"; PASS=$((PASS+1)); FINDINGS+=("BRITTLE: model match is case- and format-exact. 'Haiku'!='haiku', and a full id like 'claude-haiku-4-5' != 'haiku' would false-block."); else echo "  NOTE  case-insensitive match (rc=$rc)"; fi

# 14. Multiple in_progress: last one wins -> enforce the LAST task's requirement
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"A","description":"a.\\n\\n%s"}}]}}\n' "$(fence haiku general-purpose '-')" > "$WORK/t14"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"B","description":"b.\\n\\n%s"}}]}}\n' "$(fence opus general-purpose '-')" >> "$WORK/t14"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"1","status":"in_progress"}}]}}\n' >> "$WORK/t14"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"2","status":"in_progress"}}]}}\n' >> "$WORK/t14"
run "multi: last in_progress (B/opus) is enforced, haiku dispatch blocks" 2 "$(disp general-purpose haiku 'x' "$WORK/t14")" "$WORK/t14"

echo ""
echo "RESULT: $PASS passed, $FAIL failed"
if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  echo ""; echo "ADVERSARIAL FINDINGS:"
  for f in "${FINDINGS[@]}"; do echo "  - $f"; done
fi
exit $FAIL
