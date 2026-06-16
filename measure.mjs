#!/usr/bin/env node
// Token-footprint + structural harness for the superpowers corpus.
// Hardened per adversarial audit (2026-06-16):
//  - real BPE tokens (gpt-tokenizer cl100k) instead of chars/4 estimate
//  - always-on = the EXACT file the SessionStart hook injects (hooks/session-start:18),
//    not a substring heuristic
//  - `diff` mode computes pass/fail vs a PRE-REGISTERED threshold
//  - structural lint over every SKILL.md (frontmatter / links / code fences)
//  - refuses to overwrite an existing report without --force
import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, relative, dirname } from "node:path";
import { encode } from "gpt-tokenizer";

// --- contracts -------------------------------------------------------------
// The SessionStart hook cats EXACTLY this one file into every conversation.
const ALWAYS_ON = "skills/using-superpowers/SKILL.md";
// Pre-registered success thresholds (set BEFORE editing; see docs/).
const THRESHOLDS = {
  alwaysOnReductionPct: 30, // real-token cut on the one always-on file
  maxLintRegressions: 0,    // post lint issues must not exceed baseline
};
// Dead-weight markers for a Claude-Code-only user (reported, not auto-cut).
const CRUFT = /\b(Copilot|Codex|Cursor|opencode|activate_skill)\b/g;

const tok = (s) => { try { return encode(s).length; } catch { return Math.round(s.length / 4); } };

function walk(dir) {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p));
    else if (e.name.endsWith(".md")) out.push(p);
  }
  return out;
}

// Structural lint — cheap, deterministic, no LLM. Returns array of issue strings.
function lint(text, rel, root) {
  const issues = [];
  const isSkill = rel.endsWith("SKILL.md");
  if (isSkill) {
    const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!fm) issues.push("missing YAML frontmatter");
    else {
      if (!/^name:\s*\S/m.test(fm[1])) issues.push("frontmatter missing name:");
      if (!/^description:\s*\S/m.test(fm[1])) issues.push("frontmatter missing description:");
    }
  }
  // Balanced code fences.
  const fences = (text.match(/^```/gm) || []).length;
  if (fences % 2 !== 0) issues.push(`unbalanced code fences (${fences})`);
  // File-dependency links must resolve. SCOPE (deliberate): references/*.md, shared/*.md, and
  // @-includes — the concrete dependency types our edits can break. Plain prose ](*.md) links are
  // intentionally NOT linted: doc files (e.g. anthropic-best-practices.md) contain illustrative link
  // syntax that would false-positive. Adding a broad ](*.md) matcher flagged 14 such non-deps.
  const deps = new Set();
  for (const m of text.matchAll(/(?:@\.\/|\]\(|see\s+|`)?((?:\.\/)?(?:skills\/)?[\w./-]*(?:references|shared)\/[\w-]+\.md)/g)) deps.add(m[1]);
  for (const m of text.matchAll(/@(\.\/[\w./-]+\.md)/g)) deps.add(m[1]);
  for (const d of deps) {
    const clean = d.replace(/^\.\//, "");
    const candidates = [
      join(dirname(join(root, rel)), clean),
      join(root, clean),
      join(root, "skills", clean.replace(/^skills\//, "")),
    ];
    if (!candidates.some(existsSync)) issues.push(`broken link: ${d}`);
  }
  return issues;
}

function measure(root, outName, force) {
  const outPath = join(process.cwd(), "reports", `${outName}.json`);
  if (existsSync(outPath) && !force) {
    console.error(`refusing to overwrite ${outName}.json (pass --force). Protects the comparison point.`);
    process.exit(1);
  }
  const files = walk(join(root, "skills")).map((f) => {
    const text = readFileSync(f, "utf8");
    const rel = relative(root, f).replace(/\\/g, "/");
    return {
      file: rel,
      role: rel === ALWAYS_ON ? "always-on" : (rel.endsWith("SKILL.md") ? "on-demand-skill" : "on-demand-ref"),
      words: (text.match(/\S+/g) || []).length,
      tokens: tok(text),
      cruftHits: (text.match(CRUFT) || []).length,
      lint: lint(text, rel, root),
    };
  }).sort((a, b) => b.tokens - a.tokens);

  const sum = (k) => files.reduce((n, r) => n + r[k], 0);
  const entry = files.find((r) => r.role === "always-on");
  const lintIssues = files.filter((r) => r.lint.length).flatMap((r) => r.lint.map((i) => `${r.file}: ${i}`));
  const report = {
    root: root.replace(/\\/g, "/"),
    fileCount: files.length,
    totals: { words: sum("words"), tokens: sum("tokens"), cruftHits: sum("cruftHits") },
    alwaysOn: entry ? { file: entry.file, words: entry.words, tokens: entry.tokens, cruftHits: entry.cruftHits } : null,
    lintIssueCount: lintIssues.length,
    lintIssues,
    files,
  };
  writeFileSync(outPath, JSON.stringify(report, null, 2));

  console.log(`\nCORPUS @ ${report.root}  (real cl100k tokens)`);
  console.log(`files=${report.fileCount}  words=${report.totals.words}  tokens=${report.totals.tokens}  cruft=${report.totals.cruftHits}  lintIssues=${report.lintIssueCount}`);
  if (entry) console.log(`ALWAYS-ON (injected every conversation): ${entry.file}  ${entry.words}w  ${entry.tokens} tok  cruft=${entry.cruftHits}`);
  if (lintIssues.length) console.log("LINT:\n  " + lintIssues.join("\n  "));
  console.log(`\nwrote reports/${outName}.json`);
}

function diff(baseName, postName) {
  const b = JSON.parse(readFileSync(join(process.cwd(), "reports", `${baseName}.json`), "utf8"));
  const p = JSON.parse(readFileSync(join(process.cwd(), "reports", `${postName}.json`), "utf8"));
  if (!b.alwaysOn || !p.alwaysOn) { console.error("diff: a report has alwaysOn=null (root lacks using-superpowers/SKILL.md)"); process.exit(1); }
  const pct = (was, now) => was ? (((was - now) / was) * 100) : 0;

  const aoWas = b.alwaysOn.tokens, aoNow = p.alwaysOn.tokens, aoPct = pct(aoWas, aoNow);
  const corpPct = pct(b.totals.tokens, p.totals.tokens);
  const lintReg = p.lintIssueCount - b.lintIssueCount;

  console.log(`\n=== DELTA: ${baseName} -> ${postName} ===`);
  console.log(`ALWAYS-ON tokens : ${aoWas} -> ${aoNow}   (${aoPct.toFixed(1)}% cut)`);
  console.log(`Corpus tokens    : ${b.totals.tokens} -> ${p.totals.tokens}   (${corpPct.toFixed(1)}% cut)`);
  console.log(`Lint issues      : ${b.lintIssueCount} -> ${p.lintIssueCount}   (regressions: ${lintReg})`);

  const pass = aoPct >= THRESHOLDS.alwaysOnReductionPct && lintReg <= THRESHOLDS.maxLintRegressions;
  console.log(`\nThreshold: always-on cut >= ${THRESHOLDS.alwaysOnReductionPct}%  AND  lint regressions <= ${THRESHOLDS.maxLintRegressions}`);
  console.log(pass ? "RESULT: PASS ✅" : "RESULT: FAIL ❌");
  process.exit(pass ? 0 : 1);
}

const [mode, a, c, d] = process.argv.slice(2);
if (mode === "diff") diff(a, c);
else if (mode === "measure") measure(a || "plugin", c || "current", d === "--force" || c === "--force");
else { console.error("usage: measure.mjs measure <root> <name> [--force]  |  measure.mjs diff <baseName> <postName>"); process.exit(1); }
