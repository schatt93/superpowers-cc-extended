// Quantify the always-on REGISTRY saving: the 7 rewritten descriptions, old vs new, real tokens.
import { encode } from "gpt-tokenizer";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const skills = ["brainstorming","checking-gates","finishing-a-development-branch","receiving-code-review","specifying-gates","using-git-worktrees","verification-before-completion"];
const desc = (text) => (text.match(/^description:\s*(.*)$/m) || [,""])[1];

let o = 0, n = 0;
for (const s of skills) {
  const path = `plugin/skills/${s}/SKILL.md`;
  const oldText = execFileSync("git", ["show", `pristine-baseline:${path}`], { encoding: "utf8" }); // pristine baseline tag (pre-CSO); no shell
  const newText = readFileSync(path, "utf8");                              // post-CSO (working)
  o += encode(desc(oldText)).length;
  n += encode(desc(newText)).length;
}
console.log(`7 descriptions: ${o} -> ${n} tokens  (-${o - n}, ${(((o - n) / o) * 100).toFixed(0)}%)`);
