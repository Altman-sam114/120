// Cloud-only structure coverage using the same installed Simulator capture path.
const fs = require("node:fs");
const path = require("node:path");
const { capture } = require("./capture-terrain-previews");
const [udid, bundleID, outputDirectory = "ci-results"] = process.argv.slice(2);
const report = { outcome: "failure", scenes: [] };

async function main() {
  fs.mkdirSync(outputDirectory, { recursive: true });
  if (!udid || !bundleID) throw new Error("The pinned Simulator and installed bundle ID are required.");
  report.scenes = [await capture("structures", { map: "coast", launchArgument: "--rustwar-ci-structures" })];
  const keys = ["launchExit", "processExit", "screenshotExit", "orientationExit", "probeExit"];
  if (report.scenes.every((scene) => keys.every((key) => scene[key] === 0))) report.outcome = "success";
}
main().catch((error) => { report.error = error.message; console.error(error.message); }).finally(() => {
  fs.mkdirSync(outputDirectory, { recursive: true });
  fs.writeFileSync(path.join(outputDirectory, "ios-structures-scene.json"), `${JSON.stringify(report, null, 2)}\n`);
  process.exitCode = report.outcome === "success" ? 0 : 1;
});
