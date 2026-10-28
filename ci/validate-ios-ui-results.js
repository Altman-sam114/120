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
  "testAreaSelectionThenGroundOrder",
  "testFactoryPaletteAndUpgradeVisibleWithoutScrolling",
  "testTech2PaletteQueuesHeavyThenReturnsToBattlefield",
  "testStatusResourcesVisibleBeforeAndAfterFactoryFocus",
  "testPinchZoomDoesNotIssueOrdersAndFreshTapWorks",
  "testTwoFingerTapDoesNotIssueOrdersAndFreshTapWorks",
  "testStopRetainsStationaryInRangeDefense",
  "testRenderedSelectionAndVerticalPanFollowTheFinger",
  "testCommandCenterShowsAndQueuesBuilderThenFreshMoveWorks",
  "testRenderedUnitDetoursAroundBuildingAndArrives",
  "testSelectedForceHealthAndOrdersRemainVisible",
  "testFriendlyTapWinsOverAdjacentEnemyHalo",
  "testProductionCardsReflectQueueProgressAndCancellation"
];

function assessUIResults(summary, tree, exitCode) {
  const report = {
    outcome: "failure", executionExit: Number(exitCode), expectedTests: expected,
    total: summary.totalTestCount, passed: summary.passedTests,
    failed: summary.failedTests, skipped: summary.skippedTests,
    result: summary.result ?? summary.testResult, cases: [], foreignCases: [],
    malformedCases: [], duplicateTests: [], missingTests: [], treeTotal: 0
  };

  function visit(node, bundle, suite) {
    if (!node || typeof node !== "object") return;
    if (node.nodeType === "UI test bundle" || node.nodeType === "Unit test bundle") {
      bundle = node.nodeType === "UI test bundle" ? node.name : null;
      suite = null;
    }
    if (node.nodeType === "Test Suite") suite = node.name;
    if (node.nodeType === "Test Case") {
      report.treeTotal += 1;
      const name = typeof node.name === "string" ? node.name.replace(/\(\)$/, "") : "";
      const entry = { name, result: node.result };
      if (bundle !== "RustwarIOSUITests" || suite !== "RustwarIOSInteractionTests") {
        report.foreignCases.push(entry);
      } else if (!/^test[A-Za-z0-9_]+$/.test(name) ||
          (node.nodeIdentifier != null && node.nodeIdentifier !== `${suite}/${name}()` &&
            node.nodeIdentifier !== `${suite}/${name}`)) {
        report.malformedCases.push(entry);
      } else {
        report.cases.push(entry);
      }
    }
    for (const child of Array.isArray(node.children) ? node.children : []) visit(child, bundle, suite);
  }
  for (const root of Array.isArray(tree.testNodes) ? tree.testNodes : []) visit(root, null, null);
  const names = report.cases.map((entry) => entry.name);
  report.duplicateTests = [...new Set(names.filter((name, index) => names.indexOf(name) !== index))];
  report.missingTests = expected.filter((name) => !names.includes(name));
  report.unsuccessfulTests = report.cases.filter((entry) => entry.result !== "Passed");
  const counts = [report.total, report.passed, report.failed, report.skipped];
  if (report.executionExit === 0 && counts.every((count) => Number.isInteger(count) && count >= 0) &&
      report.total >= expected.length && report.passed === report.total &&
      report.failed === 0 && report.skipped === 0 && report.result === "Passed" &&
      (summary.expectedFailures ?? 0) === 0 && (summary.testFailures?.length ?? 0) === 0 &&
      report.total === report.treeTotal && report.total === report.cases.length &&
      report.foreignCases.length === 0 && report.malformedCases.length === 0 &&
      report.duplicateTests.length === 0 && report.missingTests.length === 0 &&
      report.unsuccessfulTests.length === 0) {
    report.outcome = "success";
  }
  return report;
}

function main() {
  const [summaryPath, testsPath, exitCode, outputPath] = process.argv.slice(2);
  let report;
  try {
    const summary = JSON.parse(fs.readFileSync(summaryPath, "utf8"));
    const tree = JSON.parse(fs.readFileSync(testsPath, "utf8"));
    report = assessUIResults(summary, tree, exitCode);
  } catch (error) {
    report = { outcome: "failure", executionExit: Number(exitCode), error: error.message };
  }
  fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report));
  process.exitCode = report.outcome === "success" ? 0 : 1;
}

if (require.main === module) main();
module.exports = { assessUIResults, expected };
