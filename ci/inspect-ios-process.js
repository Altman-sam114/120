const path = require("node:path");
const { spawnSync } = require("node:child_process");

function run(command, args, options) {
  const result = spawnSync(command, args, { encoding: "utf8", maxBuffer: 1024 * 1024, ...options });
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) console.error(result.error.message);
  return { code: result.status ?? 1, stdout: result.stdout || "", timedOut: result.error?.code === "ETIMEDOUT" };
}

function validIdentity(device, bundleID) {
  return /^[A-Za-z0-9-]+$/.test(device ?? "") && /^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*$/.test(bundleID ?? "");
}

function validContainer(container, device) {
  const deviceRoot = `/CoreSimulator/Devices/${device}/data/Containers/Bundle/Application/`;
  return typeof container === "string" && path.isAbsolute(container) && path.normalize(container) === container &&
    !/[\r\n]/.test(container) && container.includes(deviceRoot) && /\/[^/]+\.app$/.test(container);
}

// Resolve once after installation, before launching the render-heavy scenes.
// Hot-path liveness checks must not depend on Simulator IPC.
function locateInstalledApp(device, bundleID, runCommand = run) {
  const report = { exitCode: 1, device, bundleID, attempts: [] };
  if (!validIdentity(device, bundleID)) return { ...report, error: "The pinned device and bundle ID are required." };
  const result = runCommand("xcrun", ["simctl", "get_app_container", device, bundleID, "app"], { timeout: 120_000 });
  report.attempts.push({ step: "installedBundle", exitCode: result.code, timedOut: result.timedOut === true });
  if (result.code !== 0 || result.timedOut) return { ...report, exitCode: result.code || 1, error: "Installed bundle lookup failed." };
  const container = result.stdout.trim();
  if (!validContainer(container, device)) return { ...report, error: "Installed bundle path does not belong to the pinned Simulator." };
  return { ...report, exitCode: 0, appContainer: container };
}

// Simulator apps use host PIDs. Bind the prelaunch installation to the actual
// Bundle ID, executable metadata and exact launched PID using host-only tools.
function inspectLaunchedProcess(device, bundleID, pid, runCommand = run,
                                container = process.env.RUSTWAR_SIMULATOR_APP_CONTAINER) {
  const report = { exitCode: 1, device, bundleID, pid: pid ?? null, attempts: [] };
  const fail = (error, code = 1) => ({ ...report, exitCode: code || 1, error });
  if (!validIdentity(device, bundleID) ||
      !/^[1-9][0-9]*$/.test(pid ?? "")) return fail("A pinned device, bundle ID and exact launched PID are required.");
  if (!validContainer(container, device)) return fail("The prelaunch installation path is missing or belongs to another Simulator.");
  report.appContainer = container;
  report.containerSource = "prelaunchInstallation";

  const inspect = (step, command, args, timeout) => {
    const result = runCommand(command, args, { timeout });
    report.attempts.push({ step, exitCode: result.code, timedOut: result.timedOut === true });
    return result;
  };
  // Read both keys from the actual installed plist in one host process. This
  // avoids two cold PlistBuddy launches; the total metadata+ps budget stays 15s.
  const metadataResult = inspect("bundleMetadata", "/usr/bin/plutil",
    ["-convert", "json", "-o", "-", path.join(container, "Info.plist")], 10_000);
  if (metadataResult.code !== 0 || metadataResult.timedOut) return fail("Bundle metadata lookup failed.", metadataResult.code);
  let metadata;
  try { metadata = JSON.parse(metadataResult.stdout); }
  catch { return fail("Installed bundle metadata is not valid JSON."); }
  if (!metadata || typeof metadata !== "object" || Array.isArray(metadata) || metadata.CFBundleIdentifier !== bundleID) {
    return fail("The installed bundle identifier does not match the launched game.");
  }
  report.installedBundleIdentifier = metadata.CFBundleIdentifier;
  const executable = metadata.CFBundleExecutable;
  if (typeof executable !== "string" || !executable || executable.trim() !== executable ||
      executable === "." || executable === ".." || /[\\/\x00-\x1f\x7f]/.test(executable)) {
    return fail("Invalid CFBundleExecutable.");
  }
  report.executablePath = path.join(container, executable);

  const processResult = inspect("hostProcess", "/bin/ps", ["-ww", "-p", pid, "-o", "pid=,stat=,comm="], 5_000);
  if (processResult.code !== 0 || processResult.timedOut) return fail("Launched process is not available.", processResult.code);
  const observed = processResult.stdout.trim().match(/^(\d+)\s+(\S+)\s+([^\r\n]+)$/);
  if (!observed || observed[1] !== pid || observed[3] !== report.executablePath || /[TZXY]/.test(observed[2])) {
    return fail("Launched PID is stopped, dead, or does not match the installed executable.");
  }
  report.processState = observed[2];
  report.exitCode = 0;
  return report;
}

module.exports = { inspectLaunchedProcess, locateInstalledApp };
if (require.main === module) {
  const args = process.argv.slice(2);
  const locating = args[0] === "--locate";
  const report = locating ? locateInstalledApp(args[1], args[2]) : inspectLaunchedProcess(...args);
  if (locating) {
    console.error(JSON.stringify(report));
    if (report.exitCode === 0) console.log(report.appContainer);
  } else {
    console.log(JSON.stringify(report));
  }
  process.exitCode = report.exitCode;
}
