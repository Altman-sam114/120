const test = require("node:test");
const assert = require("node:assert/strict");
const { inspectLaunchedProcess } = require("./capture-terrain-previews");
const { locateInstalledApp } = require("./inspect-ios-process");

const container = "/Users/runner/Library/Developer/CoreSimulator/Devices/cloud-device/data/Containers/Bundle/Application/installed-uuid/RustwarIOS.app";
const metadata = (values = {}) => ({ code: 0, stdout: JSON.stringify({
  CFBundleIdentifier: "com.rustwar.prototype.ios", CFBundleExecutable: "RustwarIOS", ...values
}) });
const success = () => [
  metadata(),
  { code: 0, stdout: `18851 Ss ${container}/RustwarIOS\n` }
];

function fixture(results = success()) {
  const calls = [];
  return { calls, run: (pid = "18851", device = "cloud-device", bundleID = "com.rustwar.prototype.ios", installed = container) =>
    inspectLaunchedProcess(device, bundleID, pid, (...args) => {
      calls.push(args);
      return results[calls.length - 1];
    }, installed) };
}

test("host inspection verifies the installed bundle, executable and exact launched PID", () => {
  const input = fixture();
  const report = input.run();
  assert.equal(report.exitCode, 0);
  assert.equal(report.executablePath, `${container}/RustwarIOS`);
  assert.equal(report.processState, "Ss");
  assert.equal(report.installedBundleIdentifier, "com.rustwar.prototype.ios");
  assert.deepEqual(input.calls, [
    ["/usr/bin/plutil", ["-convert", "json", "-o", "-", `${container}/Info.plist`], { timeout: 10_000 }],
    ["/bin/ps", ["-ww", "-p", "18851", "-o", "pid=,stat=,comm="], { timeout: 5_000 }]
  ]);
  assert.equal(report.containerSource, "prelaunchInstallation");
  assert.deepEqual(report.attempts.map((attempt) => attempt.step), ["bundleMetadata", "hostProcess"]);
  assert.ok(report.attempts.every((attempt) => attempt.exitCode === 0 && !attempt.timedOut));
});

test("a transport timeout fails honestly without launchctl, retries or relaunches", () => {
  for (let step = 0; step < 2; step += 1) {
    const results = success();
    results[step] = { code: 1, stdout: "", timedOut: true };
    const input = fixture(results);
    const report = input.run();
    assert.equal(report.exitCode, 1);
    assert.equal(input.calls.length, step + 1);
    assert.equal(report.attempts.at(-1).timedOut, true);
    assert.ok(input.calls.every((call) => !call[1].includes("spawn") && !call[1].includes("launch")));
  }
});

test("ordinary lookup or process failures retain their actual status and stop capture", () => {
  for (let step = 0; step < 2; step += 1) {
    const results = success();
    results[step] = { code: 3, stdout: "" };
    const input = fixture(results);
    assert.equal(input.run().exitCode, 3);
    assert.equal(input.calls.length, step + 1);
  }
});

test("an absent or malformed PID cannot inspect a different process", () => {
  for (const pid of ["", null, "0", "18851/other", "-1"]) {
    const input = fixture([]);
    assert.equal(input.run(pid).exitCode, 1);
    assert.deepEqual(input.calls, []);
  }
});

test("missing device or bundle identity cannot be replaced with another app", () => {
  for (const [device, bundleID] of [["", "com.rustwar.prototype.ios"], ["cloud-device", ""], ["cloud/device", "other"]]) {
    const input = fixture([]);
    assert.equal(input.run("18851", device, bundleID).exitCode, 1);
    assert.deepEqual(input.calls, []);
  }
});

test("a bundle container from another Simulator or a relative path fails closed", () => {
  for (const value of [container.replace("cloud-device", "other-device"), "relative/RustwarIOS.app", `${container}\n${container}`, ""]) {
    const input = fixture([]);
    assert.equal(input.run("18851", "cloud-device", "com.rustwar.prototype.ios", value).exitCode, 1);
    assert.equal(input.calls.length, 0);
  }
});

test("bundle executable traversal, empty metadata and multiline metadata fail closed", () => {
  for (const value of ["", ".", "..", "../OtherApp", "RustwarIOS\nOtherApp", "RustwarIOS\\OtherApp", " RustwarIOS", 3, null, []]) {
    const results = success();
    results[0] = metadata({ CFBundleExecutable: value });
    const input = fixture(results);
    assert.equal(input.run().exitCode, 1);
    assert.equal(input.calls.length, 1);
  }
});

test("a reused PID or wrong executable cannot stand in for the launched game", () => {
  for (const value of [`18852 Ss ${container}/RustwarIOS`, `18851 Ss ${container}/OtherApp`,
    `18851 Ss ${container.replace("installed-uuid", "old-install")}/RustwarIOS`, ""]) {
    const results = success();
    results[1].stdout = value;
    assert.equal(fixture(results).run().exitCode, 1);
  }
});

test("zombie, stopped and dead states cannot satisfy the process gate", () => {
  for (const state of ["Z", "T", "TX", "Xs", "Y"]) {
    const results = success();
    results[1].stdout = `18851 ${state} ${container}/RustwarIOS`;
    assert.equal(fixture(results).run().exitCode, 1);
  }
});

test("host inspection accepts actual running or sleeping states and paths with spaces", () => {
  for (const state of ["R+", "S", "Ss", "I"]) {
    const spaced = container.replace("/Users/runner/", "/Users/cloud runner/");
    const results = success();
    results[1].stdout = ` 18851  ${state}   ${spaced}/RustwarIOS\n`;
    assert.equal(fixture(results).run("18851", "cloud-device", "com.rustwar.prototype.ios", spaced).exitCode, 0);
  }
});

test("unknown signal failures cannot turn into success", () => {
  const input = fixture([{ code: 1, stdout: "", timedOut: false }]);
  assert.equal(input.run().exitCode, 1);
  assert.equal(input.calls.length, 1);
});

test("installation resolution binds the exact device and bundle before any scene starts", () => {
  const calls = [];
  const report = locateInstalledApp("cloud-device", "com.rustwar.prototype.ios", (...args) => {
    calls.push(args);
    return { code: 0, stdout: `${container}\n` };
  });
  assert.equal(report.exitCode, 0);
  assert.equal(report.appContainer, container);
  assert.deepEqual(calls, [["xcrun", ["simctl", "get_app_container", "cloud-device", "com.rustwar.prototype.ios", "app"], { timeout: 120_000 }]]);
});

test("installation resolution rejects timeouts, failures and wrong-device paths without retries", () => {
  for (const result of [{ code: 1, timedOut: true }, { code: 3 },
    { code: 0, stdout: container.replace("cloud-device", "other-device") }, { code: 0, stdout: "relative/Game.app" }]) {
    let calls = 0;
    const report = locateInstalledApp("cloud-device", "com.rustwar.prototype.ios", () => { calls += 1; return result; });
    assert.notEqual(report.exitCode, 0);
    assert.equal(calls, 1);
  }
});

test("wrong bundle metadata cannot borrow the prelaunch installation identity", () => {
  const results = success();
  results[0] = metadata({ CFBundleIdentifier: "com.other.game" });
  const input = fixture(results);
  assert.equal(input.run().exitCode, 1);
  assert.equal(input.calls.length, 1);
});

test("five scene checks reuse one installation lookup with no hot-path Simulator IPC", () => {
  const calls = [];
  const command = (name, args) => {
    calls.push([name, args]);
    if (name === "xcrun") return { code: 0, stdout: `${container}\n` };
    if (name === "/usr/bin/plutil") return metadata();
    return { code: 0, stdout: `${args[2]} Ss ${container}/RustwarIOS\n` };
  };
  const installation = locateInstalledApp("cloud-device", "com.rustwar.prototype.ios", command);
  assert.equal(installation.exitCode, 0);
  for (const pid of ["18851", "18852", "18853", "18854", "18855"]) {
    assert.equal(inspectLaunchedProcess("cloud-device", "com.rustwar.prototype.ios", pid, command, installation.appContainer).exitCode, 0);
  }
  assert.equal(calls.filter(([name]) => name === "xcrun").length, 1);
  assert.equal(calls.filter(([name]) => name === "/usr/bin/plutil").length, 5);
  assert.equal(calls.filter(([name]) => name === "/bin/ps").length, 5);
  assert.equal(calls.length, 11);
});

test("malformed or non-dictionary metadata cannot skip actual bundle and executable checks", () => {
  for (const value of ["not JSON", "", "null", "[]", '"RustwarIOS"', "{}",
    '{"CFBundleIdentifier":42,"CFBundleExecutable":"RustwarIOS"}',
    '{"CFBundleIdentifier":"com.rustwar.prototype.ios"}']) {
    const results = success();
    results[0].stdout = value;
    const input = fixture(results);
    assert.equal(input.run().exitCode, 1);
    assert.equal(input.calls.length, 1);
  }
});
