#!/usr/bin/env node
// CSO sweep: replace workflow-summarizing descriptions with trigger-only ones.
// Per writing-skills doctrine: description = WHEN to use, third person, NO workflow summary.
// Only the 7 skills carrying the anti-pattern are touched; the other 9 are already clean.
import { readFileSync, writeFileSync } from "node:fs";

const edits = {
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

let changed = 0;
for (const [skill, desc] of Object.entries(edits)) {
  const path = `plugin/skills/${skill}/SKILL.md`;
  const t = readFileSync(path, "utf8");
  if (!/^description:.*$/m.test(t)) { console.error(`! ${skill}: no description line`); process.exit(1); }
  const next = t.replace(/^description:.*$/m, `description: ${desc}`);
  if (next !== t) { writeFileSync(path, next); changed++; console.log(`updated ${skill}`); }
  else console.log(`unchanged ${skill}`);
}
console.log(`\n${changed}/${Object.keys(edits).length} descriptions rewritten`);
