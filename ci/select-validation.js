const { execFileSync } = require("node:child_process");
const fs = require("node:fs");

function selectValidation(files, requested = "auto") {
  if (!["auto", "native"].includes(requested)) throw new Error("Unknown validation profile.");
  const changedFiles = [...new Set(files)].sort();
  const docs = changedFiles.some((file) => file.endsWith(".md"));
  const web = changedFiles.some((file) => ["app.js", "index.html", "styles.css"].includes(file));
  const ci = changedFiles.some((file) => file.startsWith("ci/") || file.startsWith(".github/"));
  const knownLightweight = (file) => file.endsWith(".md") ||
    ["app.js", "index.html", "styles.css"].includes(file) ||
    file.startsWith("ci/") || file.startsWith(".github/");
  // Unknown paths fail closed instead of silently skipping native integration.
  const native = requested === "native" || changedFiles.length === 0 ||
    changedFiles.some((file) => file.endsWith(".swift") ||
      (file.startsWith("ci/capture-") && file.endsWith(".js") && !file.endsWith(".test.js"))) ||
    changedFiles.some((file) => !knownLightweight(file));
  return {
    profile: native ? "native" : ci ? "ci" : web ? "web" : "docs",
    native, docs, web, ci, changedFiles
  };
}

function collectChanges(env = process.env, cwd = process.cwd()) {
  const sha = env.GITHUB_SHA;
  const before = env.BEFORE_SHA;
  const git = (...args) => execFileSync("git", args, { cwd, encoding: "utf8", input: "" }).trim();
  let base;
  if (before && !/^0+$/.test(before)) {
    git("cat-file", "-e", `${before}^{commit}`);
    base = before;
  } else {
    try { base = git("rev-parse", `${sha}^`); }
    catch { base = git("hash-object", "-w", "-t", "tree", "--stdin"); }
  }
  const names = execFileSync("git", ["diff", "--name-only", "--no-renames", "-z", base, sha], { cwd, encoding: "utf8" });
  return { ...selectValidation(names.split("\0").filter(Boolean), env.REQUESTED_PROFILE || "auto"), base, commitSha: sha };
}

module.exports = { selectValidation, collectChanges };
if (require.main === module) {
  const scope = collectChanges();
  fs.writeFileSync("validation-scope.json", `${JSON.stringify(scope, null, 2)}\n`);
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `profile=${scope.profile}\nnative=${scope.native}\nbase=${scope.base}\nscope=${JSON.stringify(scope)}\n`);
  console.log(JSON.stringify(scope, null, 2));
}
