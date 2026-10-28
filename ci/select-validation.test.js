const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { selectValidation, collectChanges } = require("./select-validation");

test("Markdown-only work does not request native or CI helper tests", () => {
  const result = selectValidation(["README.md", "work.md", "md/test/test.md"]);
  assert.equal(result.profile, "docs");
  assert.equal(result.native, false);
  assert.equal(result.ci, false);
  assert.equal(result.web, false);
});

test("Web changes retain document checks without requesting Apple tools", () => {
  const result = selectValidation(["app.js", "styles.css", "README.md"]);
  assert.equal(result.profile, "web");
  assert.equal(result.web, true);
  assert.equal(result.docs, true);
  assert.equal(result.native, false);
});

test("CI-only routing changes select helper validation, not App compilation", () => {
  const result = selectValidation([".github/workflows/ci-results.yml", "ci/select-validation.js"]);
  assert.equal(result.profile, "ci");
  assert.equal(result.ci, true);
  assert.equal(result.native, false);
});

test("Core, App, real capture helpers and unknown assets retain native integration", () => {
  for (const file of ["swift/RustwarCore/Package.swift", "ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift",
    "ci/validate-ios-screenshot.swift", "ci/capture-terrain-previews.js", "textures/terrain.png"]) {
    assert.equal(selectValidation(["README.md", file]).native, true, file);
  }
  assert.equal(selectValidation(["ci/capture-terrain-previews.test.js"]).native, false);
});

test("mixed pushes cannot hide native changes behind documentation", () => {
  const result = selectValidation(["README.md", "ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj"]);
  assert.equal(result.profile, "native");
  assert.equal(result.docs, true);
});

test("manual native profile overrides the lightweight route without a code change", () => {
  assert.equal(selectValidation(["README.md"], "native").native, true);
  assert.throws(() => selectValidation(["README.md"], "unknown"));
});

test("empty scope fails closed and changed files are unique and stable", () => {
  assert.equal(selectValidation([]).native, true);
  assert.deepEqual(selectValidation(["work.md", "README.md", "work.md"]).changedFiles, ["README.md", "work.md"]);
});

test("real Git ranges include earlier commits, deleted rename paths and the initial commit", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "rustwar-scope-git-"));
  const git = (...args) => execFileSync("git", args, { cwd: directory, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim();
  const commit = (message) => {
    git("add", "--all");
    git("-c", "user.name=CI", "-c", "user.email=ci@example.invalid", "commit", "-m", message);
    return git("rev-parse", "HEAD");
  };
  git("init");
  fs.writeFileSync(path.join(directory, "README.md"), "# Start\n");
  const first = commit("docs");
  assert.equal(collectChanges({ GITHUB_SHA: first }, directory).profile, "docs");
  fs.writeFileSync(path.join(directory, "Rule.swift"), "struct Rule {}\n");
  const core = commit("native");
  fs.appendFileSync(path.join(directory, "README.md"), "\nGuide\n");
  const docs = commit("more docs");
  assert.equal(collectChanges({ GITHUB_SHA: docs, BEFORE_SHA: first }, directory).native, true);
  assert.equal(collectChanges({ GITHUB_SHA: docs }, directory).profile, "docs");
  assert.equal(collectChanges({ GITHUB_SHA: docs, BEFORE_SHA: core }, directory).profile, "docs");
  fs.renameSync(path.join(directory, "Rule.swift"), path.join(directory, "Rule.md"));
  const renamed = commit("rename");
  const scope = collectChanges({ GITHUB_SHA: renamed, BEFORE_SHA: docs }, directory);
  assert.equal(scope.native, true);
  assert.ok(scope.changedFiles.includes("Rule.swift"));
  assert.ok(scope.changedFiles.includes("Rule.md"));
  assert.throws(() => collectChanges({ GITHUB_SHA: renamed, BEFORE_SHA: "does-not-exist" }, directory));
});
