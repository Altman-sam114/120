const test = require("node:test");
const assert = require("node:assert/strict");
const { assessUIResults, expected } = require("./validate-ios-ui-results");

function fixture() {
  const cases = expected.map((name) => ({
    name: `${name}()`, nodeIdentifier: `RustwarIOSInteractionTests/${name}()`,
    nodeType: "Test Case", result: "Passed"
  }));
  const suite = { name: "RustwarIOSInteractionTests", nodeType: "Test Suite", children: cases };
  const bundle = { name: "RustwarIOSUITests", nodeType: "UI test bundle", children: [suite] };
  return {
    summary: { totalTestCount: expected.length, passedTests: expected.length,
      failedTests: 0, skippedTests: 0, result: "Passed", expectedFailures: 0, testFailures: [] },
    tree: { testNodes: [{ name: "RustwarIOS", nodeType: "Test Plan", children: [bundle] }] },
    cases, suite, bundle
  };
}
function outcome(input, exitCode = 0) {
  return assessUIResults(input.summary, input.tree, exitCode).outcome;
}

test("all exact successful UI leaves in the actual xcresult schema pass", () => {
  const input = fixture();
  assert.equal(outcome(input), "success");
  assert.equal(assessUIResults(input.summary, input.tree, 0).cases.length, expected.length);
});
test("older summary testResult and bare method names remain supported", () => {
  const input = fixture();
  input.summary.testResult = input.summary.result;
  delete input.summary.result;
  input.cases.forEach((entry) => { entry.name = entry.name.replace(/\(\)$/, ""); });
  assert.equal(outcome(input), "success");
});
test("a similarly named leaf and a mention in a diagnostic cannot satisfy an absent method", () => {
  const input = fixture();
  input.cases[0].name = `${expected[0]}Extra()`;
  input.cases[0].nodeIdentifier = `RustwarIOSInteractionTests/${expected[0]}Extra()`;
  input.tree.diagnostic = expected[0];
  assert.equal(outcome(input), "failure");
  assert.deepEqual(assessUIResults(input.summary, input.tree, 0).missingTests, [expected[0]]);
});
for (const result of ["Failed", "Skipped", "Expected Failure", "Unknown", undefined]) {
  test(`a ${result} actual leaf cannot hide behind a green summary`, () => {
    const input = fixture();
    input.cases[0].result = result;
    assert.equal(outcome(input), "failure");
  });
}
for (const field of ["bundle", "suite"]) {
  test(`a foreign ${field} cannot satisfy the real UI scope`, () => {
    const input = fixture();
    input[field].name += "Other";
    assert.equal(outcome(input), "failure");
  });
}
test("a unit test bundle with matching names cannot impersonate UI execution", () => {
  const input = fixture();
  input.bundle.nodeType = "Unit test bundle";
  assert.equal(outcome(input), "failure");
});
test("a matching suite label without actual test leaves cannot pass", () => {
  const input = fixture();
  input.suite.children = [];
  input.suite.description = expected.join(" ");
  assert.equal(outcome(input), "failure");
});
test("duplicate successful leaves cannot inflate execution counts", () => {
  const input = fixture();
  input.cases.push({ ...input.cases[0] });
  input.summary.totalTestCount += 1;
  input.summary.passedTests += 1;
  assert.equal(outcome(input), "failure");
});
test("a tree count different from the summary cannot pass", () => {
  const input = fixture();
  input.summary.totalTestCount += 1;
  input.summary.passedTests += 1;
  assert.equal(outcome(input), "failure");
});
test("a contradictory node identifier cannot impersonate a required method", () => {
  const input = fixture();
  input.cases[0].nodeIdentifier = "ForeignTests/testOther()";
  assert.equal(outcome(input), "failure");
});
test("a failed runner remains failure despite every test leaf passing", () => {
  assert.equal(outcome(fixture(), 65), "failure");
});
test("string summary counts and a missing tree fail closed", () => {
  const input = fixture();
  input.summary.passedTests = String(expected.length);
  assert.equal(outcome(input), "failure");
  assert.equal(outcome({ ...fixture(), tree: {} }), "failure");
});
test("unexpected failure metadata cannot hide behind green summary counts", () => {
  const input = fixture();
  input.summary.testFailures.push({ message: "failed assertion" });
  assert.equal(outcome(input), "failure");
});
test("actual failed cases with Failure Message children remain identifiable failures", () => {
  const input = fixture();
  input.cases[0].result = "Failed";
  input.cases[0].children = [{ nodeType: "Failure Message", name: "Card clipped" }];
  const report = assessUIResults(input.summary, input.tree, 65);
  assert.equal(report.outcome, "failure");
  assert.deepEqual(report.missingTests, []);
  assert.deepEqual(report.malformedCases, []);
  assert.deepEqual(report.unsuccessfulTests, [{ name: expected[0], result: "Failed" }]);
});
