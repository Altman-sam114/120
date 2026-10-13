const test = require("node:test");
const assert = require("node:assert/strict");
const { assessPackage, requiredFiles } = require("./finalize-results");

const identity = { branch: "main", commitSha: "abc123", runId: "42", runAttempt: "2" };
function fixture() {
  return {
    manifest: { ...identity }, identity, overall: "success\n",
    junit: '<testsuites tests="10" failures="0" skipped="1"></testsuites>',
    availableFiles: [...requiredFiles], checksOutcome: "success", reporterOutcome: "success"
  };
}

test("complete current-run evidence passes", () => {
  assert.equal(assessPackage(fixture()).outcome, "success");
});
for (const outcome of ["cancelled", "failure", "skipped", ""]) {
  test(`checks ${outcome || "unknown"} cannot pass despite green test files`, () => {
    assert.equal(assessPackage({ ...fixture(), checksOutcome: outcome }).outcome, "failure");
  });
}
test("failed reporter self-tests cannot pass", () => {
  assert.equal(assessPackage({ ...fixture(), reporterOutcome: "failure" }).outcome, "failure");
});
for (const field of Object.keys(identity)) {
  test(`rejects stale ${field}`, () => {
    const input = fixture();
    input.manifest[field] = "old";
    assert.equal(assessPackage(input).outcome, "failure");
  });
}
test("missing manifest and files produce explicit diagnostics", () => {
  const result = assessPackage({ ...fixture(), manifest: null, availableFiles: [] });
  assert.equal(result.outcome, "failure");
  assert.ok(result.problems.some((p) => p.includes("ios-home.png")));
});
for (const junit of ["", '<testsuites tests="0" failures="0" skipped="0"/>',
  '<testsuites tests="10" failures="1" skipped="1"/>',
  '<testsuites tests="10" failures="0" skipped="2"/>']) {
  test(`rejects incomplete or failing JUnit ${junit}`, () => {
    assert.equal(assessPackage({ ...fixture(), junit }).outcome, "failure");
  });
}
