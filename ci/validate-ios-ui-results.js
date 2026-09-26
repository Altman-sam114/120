// Run only by GitHub Actions after xcodebuild test. Read the actual xcresult
// exports; absent reports, skipped cases, or a failed runner cannot pass.
const fs = require("node:fs");

const expected = [
  "testTankTapGroundAutomaticallyEngagesEnemy",
  "testBuilderTapGroundIssuesMove",
  "testDragPansWithoutOrdersAndFreshTapWorks",
  "testFactoryTapShowsProductionAndQueuesUnit",
  "testFactoryUpgradeUsesRealAction",
  "testUnavailableProductionDoesNotQueue",
  "testDockNavigationAndFactoryRefocus",
  "testAreaSelectionThenGroundOrder"
];
const [summaryPath, testsPath, exitCode, outputPath] = process.argv.slice(2);
const report = { outcome: "failure", executionExit: Number(exitCode), expectedTests: expected, total: 0, passed: 0, failed: 0, skipped: 0 };
try {
  const summary = JSON.parse(fs.readFileSync(summaryPath, "utf8"));
  const tests = JSON.parse(fs.readFileSync(testsPath, "utf8"));
  report.total = summary.totalTestCount;
  report.passed = summary.passedTests;
  report.failed = summary.failedTests;
  report.skipped = summary.skippedTests;
  // xcresulttool's current JSON uses `result`; older toolchains exposed
  // `testResult`. Accept both while keeping the strict Passed gate below.
  report.result = summary.result ?? summary.testResult;
  const exportedTree = JSON.stringify(tests);
  report.missingTests = expected.filter((name) => !exportedTree.includes(name));
  const counts = [report.total, report.passed, report.failed, report.skipped];
  if (report.executionExit === 0 && counts.every(Number.isInteger) &&
      report.total >= expected.length && report.passed === report.total &&
      report.failed === 0 && report.skipped === 0 && report.result === "Passed" &&
      report.missingTests.length === 0) {
    report.outcome = "success";
  }
} catch (error) {
  report.error = error.message;
}
fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report));
process.exitCode = report.outcome === "success" ? 0 : 1;
