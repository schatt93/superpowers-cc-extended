#!/usr/bin/env node
// CSO sweep: replace workflow-summarizing descriptions with trigger-only ones.
// Per writing-skills doctrine: description = WHEN to use, third person, NO workflow summary.
// Covers the 7 skills + 3 command wrappers that carried the anti-pattern; others already clean.
// Idempotent: re-running makes no change once applied.
import { readFileSync, writeFileSync } from "node:fs";

const skillEdits = {
  "brainstorming":
    "Use before any creative work — creating features, building components, adding functionality, or modifying behavior — when requirements or design are not yet nailed down.",
  "checking-gates":
    "Use when picking up a user-gate task, or when a hook demands re-validation of a gate task.",
  "finishing-a-development-branch":
    "Use when implementation is complete and tests pass, and you need to decide how to integrate the work — merge, PR, or cleanup.",
  "receiving-code-review":
    "Use when receiving code review feedback, before implementing the suggestions — especially when feedback seems unclear, wrong, or technically questionable.",
  "specifying-gates":
    "Use when a user-gate task has requiresUserSpecification=true, or the agent's do-I-know-HOW self-check returns no.",
  "using-git-worktrees":
    "Use when starting feature work that needs isolation from the current workspace, or before executing an implementation plan.",
  "verification-before-completion":
    "Use when about to claim work is complete, fixed, or passing — before committing, creating PRs, or otherwise reporting success.",
};

// Command wrappers whose descriptions carried the same anti-pattern (also in the always-on registry).
const commandEdits = {
  "brainstorm":
    "Use before any creative work — creating features, building components, adding functionality, or modifying behavior — when requirements or design are not yet nailed down.",
  "specify-gate":
    "Use when a user-gate task has requiresUserSpecification=true, or the do-I-know-HOW self-check returns no. Dormant unless the user-gate hook is registered.",
  "gate-check":
    "Use when picking up a user-gate task, or when a hook demands re-validation of a gate task. Dormant unless the user-gate opt-in hook is registered.",
};

// YAML-safe scalar: quote only when a plain scalar would be ambiguous/invalid (future-proofing).
const needsQuote = (s) => s === "" || /: | #|^[\s!&*?|>@`"'%,\[\]{}#-]|\s$/.test(s);
const yamlScalar = (s) => (needsQuote(s) ? JSON.stringify(s) : s);

function applyMap(map, tmpl, label) {
  let changed = 0;
  for (const [key, desc] of Object.entries(map)) {
    const path = tmpl(key);
    const t = readFileSync(path, "utf8");
    if (!/^description:.*$/m.test(t)) { console.error(`! ${label} ${key}: no description line`); process.exit(1); }
    const next = t.replace(/^description:.*$/m, `description: ${yamlScalar(desc)}`);
    if (next !== t) { writeFileSync(path, next); changed++; console.log(`updated ${label} ${key}`); }
  }
  return changed;
}

const s = applyMap(skillEdits, (k) => `plugin/skills/${k}/SKILL.md`, "skill");
const c = applyMap(commandEdits, (k) => `plugin/commands/${k}.md`, "command");
console.log(`\n${s} skills + ${c} commands rewritten`);
