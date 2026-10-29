const test = require("node:test");
const assert = require("node:assert/strict");
const { inspectLaunchedProcess } = require("./capture-terrain-previews");

const container = "/Users/runner/Library/Developer/CoreSimulator/Devices/cloud-device/data/Containers/Bundle/Application/installed-uuid/RustwarIOS.app";
const success = () => [
  { code: 0, stdout: `${container}\n` },
  { code: 0, stdout: "RustwarIOS\n" },
  { code: 0, stdout: `18851 Ss ${container}/RustwarIOS\n` }
];

function fixture(results = success()) {
  const calls = [];
  return { calls, run: (pid = "18851", device = "cloud-device", bundleID = "com.rustwar.prototype.ios") =>
    inspectLaunchedProcess(device, bundleID, pid, (...args) => {
      calls.push(args);
      return results[calls.length - 1];
    }) };
}

test("host inspection verifies the installed bundle, executable and exact launched PID", () => {
  const input = fixture();
  const report = input.run();
  assert.equal(report.exitCode, 0);
  assert.equal(report.executablePath, `${container}/RustwarIOS`);
  assert.equal(report.processState, "Ss");
  assert.deepEqual(input.calls, [
    ["xcrun", ["simctl", "get_app_container", "cloud-device", "com.rustwar.prototype.ios", "app"], { timeout: 20_000 }],
    ["/usr/libexec/PlistBuddy", ["-c", "Print :CFBundleExecutable", `${container}/Info.plist`], { timeout: 5_000 }],
    ["/bin/ps", ["-ww", "-p", "18851", "-o", "pid=,stat=,comm="], { timeout: 5_000 }]
  ]);
  assert.deepEqual(report.attempts.map((attempt) => attempt.step), ["installedBundle", "bundleExecutable", "hostProcess"]);
  assert.ok(report.attempts.every((attempt) => attempt.exitCode === 0 && !attempt.timedOut));
});

test("a transport timeout fails honestly without launchctl, retries or relaunches", () => {
  for (let step = 0; step < 3; step += 1) {
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
  for (let step = 0; step < 3; step += 1) {
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
  for (const value of [container.replace("cloud-device", "other-device"), "relative/RustwarIOS.app", `${container}\n${container}`]) {
    const input = fixture([{ code: 0, stdout: value }]);
    assert.equal(input.run().exitCode, 1);
    assert.equal(input.calls.length, 1);
  }
});

test("bundle executable traversal, empty metadata and multiline metadata fail closed", () => {
  for (const value of ["", ".", "..", "../OtherApp", "RustwarIOS\nOtherApp"]) {
    const results = success();
    results[1].stdout = value;
    const input = fixture(results);
    assert.equal(input.run().exitCode, 1);
    assert.equal(input.calls.length, 2);
  }
});

test("a reused PID or wrong executable cannot stand in for the launched game", () => {
  for (const value of [`18852 Ss ${container}/RustwarIOS`, `18851 Ss ${container}/OtherApp`,
    `18851 Ss ${container.replace("installed-uuid", "old-install")}/RustwarIOS`, ""]) {
    const results = success();
    results[2].stdout = value;
    assert.equal(fixture(results).run().exitCode, 1);
  }
});

test("zombie, stopped and dead states cannot satisfy the process gate", () => {
  for (const state of ["Z", "T", "TX", "Xs", "Y"]) {
    const results = success();
    results[2].stdout = `18851 ${state} ${container}/RustwarIOS`;
    assert.equal(fixture(results).run().exitCode, 1);
  }
});

test("host inspection accepts actual running or sleeping states and paths with spaces", () => {
  for (const state of ["R+", "S", "Ss", "I"]) {
    const spaced = container.replace("/Users/runner/", "/Users/cloud runner/");
    const results = success();
    results[0].stdout = `${spaced}\n`;
    results[2].stdout = ` 18851  ${state}   ${spaced}/RustwarIOS\n`;
    assert.equal(fixture(results).run().exitCode, 0);
  }
});

test("unknown signal failures cannot turn into success", () => {
  const input = fixture([{ code: 1, stdout: "", timedOut: false }]);
  assert.equal(input.run().exitCode, 1);
  assert.equal(input.calls.length, 1);
});
