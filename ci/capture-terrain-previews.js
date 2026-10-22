// Cloud-only continuation of the pinned Simulator visual checks. Reuses the
// already booted device and installed app; it never creates another device.
const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const [udid, bundleID, outputDirectory = "ci-results"] = process.argv.slice(2);
const report = { outcome: "failure", scenes: [] };
const reportPath = path.join(outputDirectory, "ios-terrain-scenes.json");
const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function run(command, args) {
  const result = spawnSync(command, args, { encoding: "utf8", timeout: 120_000, maxBuffer: 16 * 1024 * 1024 });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) console.error(result.error.message);
  return { code: result.status ?? 1, stdout: result.stdout || "" };
}

async function capture(map) {
  const started = Date.now();
  const scene = {
    map, launchArgument: `--rustwar-ci-terrain-${map}`,
    screenshotPath: path.join(outputDirectory, `ios-${map}.png`),
    metricsPath: path.join(outputDirectory, `ios-${map}-screenshot-metrics.txt`),
    launchExit: 77, processExit: 77, screenshotExit: 77, orientationExit: 77, probeExit: 77
  };
  console.log(`== ${map} terrain visual scene ==`);
  run("xcrun", ["simctl", "terminate", udid, bundleID]);
  const launched = run("xcrun", ["simctl", "launch", udid, bundleID, scene.launchArgument]);
  scene.launchExit = launched.code;
  if (scene.launchExit === 0) {
    const pid = launched.stdout.trim().match(/: (\d+)$/)?.[1];
    await wait(5_000);
    scene.processExit = pid ? run("xcrun", ["simctl", "spawn", udid, "launchctl", "print", `pid/${pid}`]).code : 1;
  }
  if (scene.processExit === 0) {
    scene.screenshotExit = run("xcrun", ["simctl", "io", udid, "screenshot", "--type=png", scene.screenshotPath]).code;
  }
  if (scene.screenshotExit === 0) {
    scene.orientationExit = run("sips", ["--rotate", "270", scene.screenshotPath]).code;
  }
  if (scene.orientationExit === 0) {
    scene.probeExit = run("xcrun", ["swift", "ci/validate-ios-screenshot.swift", scene.screenshotPath, scene.metricsPath]).code;
  }
  scene.durationMilliseconds = Date.now() - started;
  console.log(JSON.stringify(scene));
  return scene;
}

async function main() {
  fs.mkdirSync(outputDirectory, { recursive: true });
  if (!udid || !bundleID) throw new Error("The pinned Simulator UDID and installed bundle ID are required.");
  for (const map of ["islands", "lava"]) report.scenes.push(await capture(map));
  // Diagnostic only: elapsed atlas baking is not a physical-device FPS result.
  run("xcrun", ["simctl", "spawn", udid, "log", "show", "--last", "5m", "--style", "compact",
    "--predicate", 'subsystem == "com.rustwar.terrain"', "--info"]);
  const keys = ["launchExit", "processExit", "screenshotExit", "orientationExit", "probeExit"];
  if (report.scenes.length === 2 && report.scenes.every((scene) => keys.every((key) => scene[key] === 0))) {
    report.outcome = "success";
  }
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  process.exitCode = report.outcome === "success" ? 0 : 1;
}

main().catch((error) => {
  report.error = error.message;
  fs.mkdirSync(outputDirectory, { recursive: true });
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.error(error.message);
  process.exitCode = 1;
});
