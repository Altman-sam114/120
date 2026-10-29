const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { localLinkProblems, relatedNodeTests, writePackage } = require("./run-scoped-checks");

test("local links resolve relative to the document and ignore external URLs and code examples", () => {
  const seen = [];
  const source = '[ok](../AGENTS.md) [web](https://example.com) [anchor](#plan)\n```md\n[example](missing.md)\n```\n`[example](inline.md)`';
  assert.deepEqual(localLinkProblems("md/guide.md", source, (file) => { seen.push(file); return true; }), []);
  assert.deepEqual(seen, [path.resolve("AGENTS.md")]);
});

test("missing and malformed local links fail without fetching any network resource", () => {
  assert.equal(localLinkProblems("README.md", "[gone](gone.md) [invalid](%GG.md)", () => false).length, 2);
});

test("helper tests are selected by the edited helper rather than a global test wildcard", () => {
  assert.deepEqual(relatedNodeTests(["ci/select-validation.js", "ci/select-validation.test.js", "README.md"], () => true), ["ci/select-validation.test.js"]);
  assert.deepEqual(relatedNodeTests(["ci/png-pixels.js", "ci/unit-art.test.js"], () => true), ["ci/building-art.test.js", "ci/effect-art.test.js", "ci/resource-art.test.js", "ci/unit-art.test.js"]);
  assert.deepEqual(relatedNodeTests(["ci/inspect-ios-process.js"], () => true), ["ci/capture-terrain-previews.test.js"]);
  assert.deepEqual(relatedNodeTests(["ci/deleted.js"], () => false), []);
});

test("scoped artifacts preserve identity, raw failures and unselected native coverage", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "rustwar-scoped-report-"));
  const env = { GITHUB_REF_NAME: "main", GITHUB_SHA: "abc", GITHUB_RUN_ID: "123", GITHUB_RUN_ATTEMPT: "2" };
  const scope = { profile: "ci", changedFiles: ["ci/select-validation.js"], base: "def" };
  const result = writePackage(directory, scope, [{ name: 'failed <check> & "detail"', exit: 7 }], env);
  assert.equal(result.pipelineOutcome, "failure");
  assert.equal(result.commitSha, "abc");
  assert.equal(result.runAttempt, "2");
  assert.equal(result.checks[0].exit, 7);
  assert.ok(result.notSelected.includes("native UI"));
  const junit = fs.readFileSync(path.join(directory, "junit.xml"), "utf8");
  assert.match(junit, /failures="1"/);
  assert.match(junit, /&lt;check&gt; &amp; &quot;detail&quot;/);
  assert.equal(fs.readFileSync(path.join(directory, "overall-status.txt"), "utf8"), "failure\n");
});

test("a report with no executed checks cannot claim success", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "rustwar-empty-report-"));
  assert.equal(writePackage(directory, { profile: "docs", changedFiles: [] }, [], {}).pipelineOutcome, "failure");
  assert.match(fs.readFileSync(path.join(directory, "junit.xml"), "utf8"), /failures="1"/);
});
