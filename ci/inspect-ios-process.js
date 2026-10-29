const path = require("node:path");
const { spawnSync } = require("node:child_process");

function run(command, args, options) {
  const result = spawnSync(command, args, { encoding: "utf8", maxBuffer: 1024 * 1024, ...options });
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) console.error(result.error.message);
  return { code: result.status ?? 1, stdout: result.stdout || "", timedOut: result.error?.code === "ETIMEDOUT" };
}

// Simulator apps use host PIDs. Inspect that exact PID without spawning a
// launchctl process inside the Simulator, whose IPC can hang on healthy apps.
function inspectLaunchedProcess(device, bundleID, pid, runCommand = run) {
  const report = { exitCode: 1, device, bundleID, pid: pid ?? null, attempts: [] };
  const fail = (error, code = 1) => ({ ...report, exitCode: code || 1, error });
  if (!/^[A-Za-z0-9-]+$/.test(device ?? "") || !/^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*$/.test(bundleID ?? "") ||
      !/^[1-9][0-9]*$/.test(pid ?? "")) return fail("A pinned device, bundle ID and exact launched PID are required.");

  const inspect = (step, command, args, timeout) => {
    const result = runCommand(command, args, { timeout });
    report.attempts.push({ step, exitCode: result.code, timedOut: result.timedOut === true });
    return result;
  };
  const containerResult = inspect("installedBundle", "xcrun",
    ["simctl", "get_app_container", device, bundleID, "app"], 20_000);
  if (containerResult.code !== 0 || containerResult.timedOut) return fail("Installed bundle lookup failed.", containerResult.code);
  const container = containerResult.stdout.trim();
  const deviceRoot = `/CoreSimulator/Devices/${device}/data/Containers/Bundle/Application/`;
  if (!path.isAbsolute(container) || path.normalize(container) !== container || container.includes("\n") ||
      !container.includes(deviceRoot) || !/\/[^/]+\.app$/.test(container)) {
    return fail("Installed bundle path does not belong to the pinned Simulator.");
  }
  report.appContainer = container;

  const executableResult = inspect("bundleExecutable", "/usr/libexec/PlistBuddy",
    ["-c", "Print :CFBundleExecutable", path.join(container, "Info.plist")], 5_000);
  if (executableResult.code !== 0 || executableResult.timedOut) return fail("Bundle executable lookup failed.", executableResult.code);
  const executable = executableResult.stdout.trim();
  if (!executable || executable === "." || executable === ".." || /[\/\r\n]/.test(executable)) {
    return fail("Invalid CFBundleExecutable.");
  }
  report.executablePath = path.join(container, executable);

  const processResult = inspect("hostProcess", "/bin/ps", ["-ww", "-p", pid, "-o", "pid=,stat=,comm="], 5_000);
  if (processResult.code !== 0 || processResult.timedOut) return fail("Launched process is not available.", processResult.code);
  const process = processResult.stdout.trim().match(/^(\d+)\s+(\S+)\s+([^\r\n]+)$/);
  if (!process || process[1] !== pid || process[3] !== report.executablePath || /[TZXY]/.test(process[2])) {
    return fail("Launched PID is stopped, dead, or does not match the installed executable.");
  }
  report.processState = process[2];
  report.exitCode = 0;
  return report;
}

module.exports = { inspectLaunchedProcess };
if (require.main === module) {
  const report = inspectLaunchedProcess(...process.argv.slice(2));
  console.log(JSON.stringify(report));
  process.exitCode = report.exitCode;
}
