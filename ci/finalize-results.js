const fs = require("node:fs");
const path = require("node:path");

const requiredFiles = [
  "build.log", "junit.xml", "ci-failure-summary.md", "repo-state.txt", "ci-reporting-tests.log",
  "toolchain-info.txt", "ios-simulator-info.txt", "ios-home.png", "ios-combat.png",
  "ios-screenshot-metrics.txt", "ios-combat-screenshot-metrics.txt",
  "ios-ui-test-summary.json", "ios-ui-test-tree.json", "ios-ui-test-gate.json",
  "ios-terrain-scenes.json", "ios-islands.png", "ios-lava.png",
  "ios-islands-screenshot-metrics.txt", "ios-lava-screenshot-metrics.txt",
  "ios-structures.png", "ios-structures-screenshot-metrics.txt", "ios-structures-scene.json"
];

function assessPackage({ manifest, overall, junit, availableFiles, checksOutcome, reporterOutcome, identity }) {
  const problems = [];
  if (checksOutcome !== "success") problems.push(`Checks step ended with ${checksOutcome || "unknown"}.`);
  if (reporterOutcome !== "success") problems.push(`CI reporting tests ended with ${reporterOutcome || "unknown"}.`);
  for (const file of requiredFiles) {
    if (!availableFiles.includes(file)) problems.push(`Missing or empty result file: ${file}.`);
  }
  if (!manifest) problems.push("Result manifest is missing or invalid.");
  if (manifest?.pixelProbeCompilerOutcome !== "success" || manifest?.pixelProbeCompilerExit !== 0) {
    problems.push("The current screenshot pixel probe did not compile successfully.");
  }
  const terrain = manifest?.terrainVisualReport;
  if (terrain?.outcome !== "success" || !Array.isArray(terrain?.scenes) || terrain.scenes.length !== 2) {
    problems.push("Terrain visual coverage must contain both successful map scenes.");
  }
  for (const map of ["islands", "lava"]) {
    const scenes = Array.isArray(terrain?.scenes) ? terrain.scenes.filter((scene) => scene?.map === map) : [];
    const scene = scenes[0];
    const stages = ["launchExit", "processExit", "screenshotExit", "orientationExit", "probeExit"];
    if (scenes.length !== 1 || !scene || stages.some((key) => scene[key] !== 0) ||
        scene.launchArgument !== `--rustwar-ci-terrain-${map}` ||
        scene.screenshotPath !== `ci-results/ios-${map}.png` ||
        scene.metricsPath !== `ci-results/ios-${map}-screenshot-metrics.txt`) {
      problems.push(`Terrain visual evidence is missing, mismatched or failed: ${map}.`);
    }
  }
  const structures = manifest?.structureVisualReport;
  const structure = structures?.scenes?.[0];
  if (structures?.outcome !== "success" || !Array.isArray(structures?.scenes) || structures.scenes.length !== 1 ||
      structure?.scenario !== "structures" || structure?.map !== "coast" ||
      structure?.launchArgument !== "--rustwar-ci-structures" ||
      structure?.screenshotPath !== "ci-results/ios-structures.png" ||
      structure?.metricsPath !== "ci-results/ios-structures-screenshot-metrics.txt" ||
      ["launchExit", "processExit", "screenshotExit", "orientationExit", "probeExit"].some((key) => structure?.[key] !== 0)) {
    problems.push("Structure visual coverage is missing, mismatched or failed.");
  }
  for (const key of ["branch", "commitSha", "runId", "runAttempt"]) {
    if (!identity[key] || String(manifest?.[key]) !== String(identity[key])) {
      problems.push(`Manifest identity mismatch: ${key}.`);
    }
  }
  if (overall.trim() !== "success") problems.push("Checks did not report overall success.");
  if (!/<testsuites\b[^>]*\btests="10"/.test(junit) ||
      !/<testsuites\b[^>]*\bfailures="0"/.test(junit) ||
      !/<testsuites\b[^>]*\bskipped="1"/.test(junit) || /<failure\b|<error\b/.test(junit)) {
    problems.push("Checks JUnit is incomplete or has unexpected failures/skips.");
  }
  return { outcome: problems.length ? "failure" : "success", problems };
}

function finalize(directory, env) {
  fs.mkdirSync(directory, { recursive: true });
  const read = (name) => {
    try { return fs.readFileSync(path.join(directory, name), "utf8"); }
    catch { return ""; }
  };
  let manifest;
  try { manifest = JSON.parse(read("ci-artifact-manifest.json")); } catch { manifest = null; }
  const identity = {
    branch: env.GITHUB_REF_NAME, commitSha: env.GITHUB_SHA,
    runId: env.GITHUB_RUN_ID, runAttempt: env.GITHUB_RUN_ATTEMPT
  };
  const junit = read("junit.xml");
  const availableFiles = requiredFiles.filter((name) => {
    try { return fs.statSync(path.join(directory, name)).size > 0; } catch { return false; }
  });
  const report = assessPackage({
    manifest, junit, availableFiles, identity, overall: read("overall-status.txt"),
    checksOutcome: env.CHECKS_STEP_OUTCOME, reporterOutcome: env.REPORTER_TEST_OUTCOME
  });
  const write = (name, value) => fs.writeFileSync(path.join(directory, name), value);
  const escape = (value) => value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/"/g, "&quot;");
  const gate = `    <testcase classname="rustwar.ci" name="CI execution and package integrity">${
    report.outcome === "success" ? "" : `<failure message="${escape(report.problems.join(" "))}"/>`
  }</testcase>`;
  // Preserve completed test evidence; interrupted jobs still publish a failing gate.
  const suites = junit.match(/<testsuite\b[\s\S]*<\/testsuite>/)?.[0];
  const oldFailures = Number(junit.match(/<testsuites\b[^>]*failures="(\d+)"/)?.[1] || 0);
  const oldTests = Number(junit.match(/<testsuites\b[^>]*tests="(\d+)"/)?.[1] || 0);
  const oldSkipped = Number(junit.match(/<testsuites\b[^>]*skipped="(\d+)"/)?.[1] || 0);
  const failed = report.outcome === "success" ? 0 : 1;
  write("junit.xml", `<?xml version="1.0" encoding="UTF-8"?>\n<testsuites tests="${(suites ? oldTests : 0) + 1}" failures="${(suites ? oldFailures : 0) + failed}" skipped="${suites ? oldSkipped : 0}">\n${suites || ""}\n  <testsuite name="CI execution integrity" tests="1" failures="${failed}" skipped="0">\n${gate}\n  </testsuite>\n</testsuites>\n`);
  const completedSummary = read("ci-failure-summary.md");
  write("ci-failure-summary.md", `## Authoritative CI Result\n- Result: ${report.outcome}\n- Checks step: ${env.CHECKS_STEP_OUTCOME || "unknown"}\n- Reporter tests: ${env.REPORTER_TEST_OUTCOME || "unknown"}\n${report.problems.map((p) => `- ${p}\n`).join("")}\n### Checks recorded before finalization\n${completedSummary.replace(/^## CI Failure Summary\n/, "")}`);
  write("overall-status.txt", `${report.outcome}\n`);
  write("ci-artifact-manifest.json", `${JSON.stringify({
    ...(manifest || { version: env.CI_FLOW_VERSION, ...identity }),
    pipelineOutcome: report.outcome, checksStepOutcome: env.CHECKS_STEP_OUTCOME || "unknown",
    reporterTestOutcome: env.REPORTER_TEST_OUTCOME || "unknown",
    packageIntegrityProblems: report.problems
  }, null, 2)}\n`);
  console.log(JSON.stringify(report));
  return report;
}

module.exports = { assessPackage, requiredFiles, finalize };
if (require.main === module) finalize(process.argv[2] || "ci-results", process.env);
