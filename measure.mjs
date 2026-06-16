#!/usr/bin/env node
// Token-footprint measurement harness for the superpowers corpus.
// Run before and after the rework; the DELTA is the deliverable.
// Token estimate = chars/4 (consistent relative proxy, not an exact tokenizer).
import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, relative } from "node:path";

const ROOT = process.argv[2] || join(process.cwd(), "plugin");
const SKILLS = join(ROOT, "skills");
const TOK = (s) => Math.round(s.length / 4);
// Keywords that are dead weight for a Claude-Code-only user.
const CRUFT = /\b(Copilot|Gemini|Codex|Cursor|opencode|GEMINI\.md|activate_skill)\b/g;

function walk(dir) {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p));
    else if (e.name.endsWith(".md")) out.push(p);
  }
  return out;
}

const files = existsSync(SKILLS) ? walk(SKILLS) : [];
const rows = files.map((f) => {
  const text = readFileSync(f, "utf8");
  const rel = relative(ROOT, f).replace(/\\/g, "/");
  return {
    file: rel,
    isEntry: rel.includes("using-superpowers"),
    chars: text.length,
    words: (text.match(/\S+/g) || []).length,
    estTokens: TOK(text),
    cruftHits: (text.match(CRUFT) || []).length,
  };
});

rows.sort((a, b) => b.estTokens - a.estTokens);
const sum = (k) => rows.reduce((n, r) => n + r[k], 0);
const entry = rows.find((r) => r.isEntry && r.file.endsWith("SKILL.md"));

const report = {
  root: ROOT.replace(/\\/g, "/"),
  fileCount: rows.length,
  totals: { chars: sum("chars"), words: sum("words"), estTokens: sum("estTokens"), cruftHits: sum("cruftHits") },
  alwaysOn: entry ? { file: entry.file, words: entry.words, estTokens: entry.estTokens } : null,
  files: rows,
};

const W = (n) => String(n).padStart(7);
console.log(`\nCORPUS @ ${report.root}`);
console.log(`files=${report.fileCount}  words=${report.totals.words}  estTokens~${report.totals.estTokens}  cruftHits=${report.totals.cruftHits}`);
if (entry) console.log(`ALWAYS-ON (hook-injected every conversation): ${entry.words} words ~${entry.estTokens} tok\n`);
console.log(`${"estTok".padStart(7)} ${"words".padStart(6)} ${"cruft".padStart(5)}  file`);
for (const r of rows) console.log(`${W(r.estTokens)} ${String(r.words).padStart(6)} ${String(r.cruftHits).padStart(5)}  ${r.file}${r.isEntry ? "  <-- ALWAYS-ON" : ""}`);

const outName = process.argv[3] || "baseline";
const outPath = join(process.cwd(), "reports", `${outName}.json`);
writeFileSync(outPath, JSON.stringify(report, null, 2));
console.log(`\nwrote ${relative(process.cwd(), outPath).replace(/\\/g, "/")}`);
