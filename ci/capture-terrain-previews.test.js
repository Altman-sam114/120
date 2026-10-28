const test = require("node:test");
const assert = require("node:assert/strict");
const { inspectLaunchedProcess } = require("./capture-terrain-previews");

function fixture(results) {
  const calls = [], pauses = [];
  return { calls, pauses,
    run: async (pid = "18851") => inspectLaunchedProcess("cloud-device", pid,
      (...args) => { calls.push(args); return results[calls.length - 1]; },
      async (milliseconds) => { pauses.push(milliseconds); }) };
}
test("a successful process inspection uses exactly the launched PID and pinned device", async () => {
  const input = fixture([{ code: 0 }]);
  assert.equal((await input.run()).exitCode, 0);
  assert.deepEqual(input.calls, [["xcrun", ["simctl", "spawn", "cloud-device", "launchctl", "print", "pid/18851"], { timeout: 30_000 }]]);
  assert.deepEqual(input.pauses, []);
});
test("one transport timeout retries the same PID once and preserves both outcomes", async () => {
  const input = fixture([{ code: 1, timedOut: true }, { code: 0 }]);
  assert.deepEqual(await input.run(), { exitCode: 0, attempts: [{ exitCode: 1, timedOut: true }, { exitCode: 0, timedOut: false }] });
  assert.deepEqual(input.calls[0], input.calls[1]);
  assert.deepEqual(input.pauses, [1_000]);
});
test("two timeouts fail without relaunching or a third attempt", async () => {
  const input = fixture([{ code: 1, timedOut: true }, { code: 1, timedOut: true }]);
  assert.equal((await input.run()).exitCode, 1);
  assert.equal(input.calls.length, 2);
});
test("ordinary process failure is not retried or accepted", async () => {
  const input = fixture([{ code: 3 }]);
  assert.equal((await input.run()).exitCode, 3);
  assert.equal(input.calls.length, 1);
});
test("an absent or malformed PID cannot inspect a different process", async () => {
  for (const pid of ["", null, "0", "18851/other", "-1"]) {
    const input = fixture([]);
    assert.equal((await input.run(pid)).exitCode, 1);
    assert.deepEqual(input.calls, []);
  }
});
test("an unknown signal exit is not a retryable transport timeout", async () => {
  const input = fixture([{ code: 1, timedOut: false }]);
  assert.equal((await input.run()).exitCode, 1);
  assert.equal(input.calls.length, 1);
});
