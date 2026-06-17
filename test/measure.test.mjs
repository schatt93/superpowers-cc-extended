// Unit tests for the measure.mjs workbench logic — node:test, zero extra deps.
// Run: npm test   (or: node --test test/)
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { stripFrontmatter, isSubsequence, normalizeRebrand, lint } from "../measure.mjs";

// --- isSubsequence: the heart of the body-preservation gate -----------------
test("isSubsequence: identical bodies pass", () => {
  assert.ok(isSubsequence(["a", "b", "c"], ["a", "b", "c"]));
});
test("isSubsequence: additive insertions are allowed", () => {
  assert.ok(isSubsequence(["a", "b"], ["a", "x", "b", "y"]));
});
test("isSubsequence: a deleted line is rejected", () => {
  assert.ok(!isSubsequence(["a", "b", "c"], ["a", "c"]));
});
test("isSubsequence: reordering is rejected", () => {
  assert.ok(!isSubsequence(["a", "b"], ["b", "a"]));
});
test("isSubsequence: an edited line is rejected", () => {
  assert.ok(!isSubsequence(["keep this"], ["keep that"]));
});

// --- stripFrontmatter -------------------------------------------------------
test("stripFrontmatter removes the YAML block and normalizes CRLF", () => {
  assert.equal(stripFrontmatter("---\nname: x\ndescription: y\n---\nBODY\nmore"), "BODY\nmore");
  assert.equal(stripFrontmatter("---\r\nname: x\r\n---\r\nBODY"), "BODY");
  assert.equal(stripFrontmatter("no frontmatter here"), "no frontmatter here");
});

// --- normalizeRebrand: the one sanctioned transform -------------------------
test("normalizeRebrand maps the bare prefix but leaves the extended one", () => {
  assert.equal(normalizeRebrand("via superpowers:using-git-worktrees now"),
    "via superpowers-extended-cc:using-git-worktrees now");
  assert.equal(normalizeRebrand("superpowers-extended-cc:foo"), "superpowers-extended-cc:foo");
});

// --- gate semantics: rebrand transparent, real edits caught -----------------
test("body gate: a pure prefix rebrand reads as unchanged; a real edit does not", () => {
  const norm = (t) => normalizeRebrand(stripFrontmatter(t)).split("\n");
  const pristine = "---\nn: x\n---\nrefer to superpowers:foo\nline two";
  const rebranded = "---\nn: x\n---\nrefer to superpowers-extended-cc:foo\nline two";
  const gutted = "---\nn: x\n---\nGUTTED";
  assert.ok(isSubsequence(norm(pristine), norm(rebranded)), "prefix rebrand must be transparent");
  assert.ok(!isSubsequence(norm(pristine), norm(gutted)), "a gutted body must be caught");
});

// --- lint: needs a small on-disk fixture (it resolves reference links) -------
test("lint: a valid skill passes and each defect is caught", () => {
  const root = mkdtempSync(join(tmpdir(), "measure-lint-"));
  try {
    const skillDir = join(root, "skills", "demo");
    mkdirSync(join(skillDir, "references"), { recursive: true });
    writeFileSync(join(skillDir, "references", "ok.md"), "ref");

    const good = "---\nname: demo\ndescription: when to use\n---\nbody\nsee references/ok.md\n```\nfenced\n```\n";
    assert.deepEqual(lint(good, "skills/demo/SKILL.md", root), [], "clean skill yields no issues");

    const noName = "---\ndescription: d\n---\nbody";
    assert.ok(lint(noName, "skills/demo/SKILL.md", root).some((i) => /missing name/.test(i)));

    const noDesc = "---\nname: demo\n---\nbody";
    assert.ok(lint(noDesc, "skills/demo/SKILL.md", root).some((i) => /missing description/.test(i)));

    const badFences = "---\nname: demo\ndescription: d\n---\n```\nunbalanced";
    assert.ok(lint(badFences, "skills/demo/SKILL.md", root).some((i) => /unbalanced/.test(i)));

    const brokenLink = "---\nname: demo\ndescription: d\n---\nsee references/missing.md";
    assert.ok(lint(brokenLink, "skills/demo/SKILL.md", root).some((i) => /broken link/.test(i)));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
