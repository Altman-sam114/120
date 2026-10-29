const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function localLinkProblems(file, source, exists = fs.existsSync) {
  const problems = [];
  const text = source.replace(/^(`{3,}|~{3,})[^\n]*\n[\s\S]*?^\1[^\n]*$/gm, "").replace(/`[^`\n]+`/g, "");
  for (const match of text.matchAll(/\]\(\s*(<[^>]+>|[^\s)]+)(?:\s+"[^"]*")?\s*\)/g)) {
    const target = match[1].replace(/^<|>$/g, "");
    if (/^(?:[a-z][a-z\d+.-]*:|#|\/\/)/i.test(target)) continue;
    try {
      const relative = decodeURIComponent(target.split(/[?#]/)[0]);
      if (relative && !exists(path.resolve(path.dirname(file), relative))) problems.push(`${file}: missing ${target}`);
    } catch { problems.push(`${file}: invalid link ${target}`); }
  }
  return problems;
}

function relatedNodeTests(files, exists = fs.existsSync) {
  const selected = new Set();
  const dependentTests = {
    "ci/png-pixels.js": ["ci/unit-art.test.js", "ci/effect-art.test.js", "ci/building-art.test.js"],
    "ci/inspect-ios-process.js": ["ci/capture-terrain-previews.test.js"]
  };
  for (const file of files.filter((name) => /^ci\/.*\.js$/.test(name))) {
    const tests = dependentTests[file] || [file.endsWith(".test.js") ? file : file.replace(/\.js$/, ".test.js")];
    for (const testFile of tests) {
      if (exists(testFile)) selected.add(testFile);
    }
  }
  return [...selected].sort();
}

function writePackage(directory, scope, checks, env = process.env) {
  if (checks.length === 0) checks = [{ name: "Required checks were not executed", exit: 1 }];
  const escape = (value) => String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const failures = checks.filter((check) => check.exit !== 0);
  const outcome = checks.length > 0 && failures.length === 0 ? "success" : "failure";
  const manifest = {
    version: "v1.2", validationProfile: scope.profile,
    branch: env.GITHUB_REF_NAME, commitSha: env.GITHUB_SHA,
    runId: env.GITHUB_RUN_ID, runAttempt: env.GITHUB_RUN_ATTEMPT,
    workflowName: env.GITHUB_WORKFLOW, createdAt: new Date().toISOString(),
    diffBase: scope.base, changedFiles: scope.changedFiles,
    pipelineOutcome: outcome, checks,
    notSelected: ["Swift package", "Xcode build", "Simulator", "native UI", "screenshots", "browser regression"],
    junitPath: "ci-results/junit.xml", buildLogPath: "ci-results/build.log",
    failureSummaryPath: "ci-results/ci-failure-summary.md"
  };
  const write = (name, content) => fs.writeFileSync(path.join(directory, name), content);
  write("ci-artifact-manifest.json", `${JSON.stringify(manifest, null, 2)}\n`);
  write("junit.xml", `<?xml version="1.0" encoding="UTF-8"?>\n<testsuites tests="${checks.length}" failures="${failures.length}" skipped="0"><testsuite name="Scoped checks" tests="${checks.length}" failures="${failures.length}" skipped="0">${checks.map((check) => `<testcase name="${escape(check.name)}">${check.exit === 0 ? "" : `<failure message="exit ${escape(check.exit)}; see build.log"/>`}</testcase>`).join("")}</testsuite></testsuites>\n`);
  write("ci-failure-summary.md", `# Scoped CI Result\n\n- Profile: ${scope.profile}\n- Result: ${outcome}\n${checks.map((check) => `- ${check.name}: exit ${check.exit}\n`).join("")}\nNative build, UI, screenshots and browser regression were not selected; this is not gameplay acceptance.\n`);
  write("overall-status.txt", `${outcome}\n`);
  return manifest;
}

function main(env = process.env) {
  const scope = JSON.parse(env.VALIDATION_SCOPE);
  if (scope.native || !["docs", "web", "ci"].includes(scope.profile) || scope.commitSha !== env.GITHUB_SHA) {
    throw new Error("Invalid lightweight scope or commit identity.");
  }
  const directory = "ci-results";
  fs.mkdirSync(directory, { recursive: true });
  fs.appendFileSync(env.GITHUB_ENV, `ARTIFACT_NAME=rustwar-ci-v1.2-main-${env.GITHUB_SHA.slice(0, 7)}-run${env.GITHUB_RUN_ID}-attempt${env.GITHUB_RUN_ATTEMPT}\n`);
  const checks = [];
  fs.writeFileSync(`${directory}/validation-scope.json`, `${JSON.stringify(scope, null, 2)}\n`);
  fs.writeFileSync(`${directory}/build.log`, `profile=${scope.profile}\nbranch=${env.GITHUB_REF_NAME}\ncommit=${env.GITHUB_SHA}\nrun=${env.GITHUB_RUN_ID}\nattempt=${env.GITHUB_RUN_ATTEMPT}\n`);
  const check = (name, command, args) => {
    const result = spawnSync(command, args, { encoding: "utf8", timeout: 120000, maxBuffer: 16 * 1024 * 1024 });
    const output = `${result.stdout || ""}${result.stderr || ""}${result.error ? `${result.error}\n` : ""}`;
    fs.appendFileSync(`${directory}/build.log`, `\n== ${name} ==\n${command} ${args.join(" ")}\n${output}\nexit=${result.status ?? 1}\n`);
    process.stdout.write(`${name}\n${output}`);
    checks.push({ name, exit: result.status ?? 1 });
  };
  check("git diff --check", "git", ["diff", "--check", scope.base, env.GITHUB_SHA]);
  if (scope.docs) {
    const problems = [];
    for (const file of scope.changedFiles.filter((name) => name.endsWith(".md") && fs.existsSync(name))) {
      problems.push(...localLinkProblems(file, fs.readFileSync(file, "utf8")));
    }
    const output = problems.length ? problems.join("\n") : "Changed Markdown local file links exist (anchors/external URLs not checked).";
    fs.appendFileSync(`${directory}/build.log`, `\n== Markdown local links ==\n${output}\n`);
    console.log(output);
    checks.push({ name: "Markdown local file links", exit: problems.length ? 1 : 0 });
  }
  if (scope.web && fs.existsSync("app.js")) check("Web JavaScript syntax", "node", ["--check", "app.js"]);
  if (scope.ci) {
    for (const file of fs.readdirSync(".github/workflows").filter((name) => /\.ya?ml$/.test(name)).sort()) {
      check(`Workflow YAML ${file}`, "ruby", ["-e", 'require "yaml"; YAML.parse_file(ARGV.fetch(0)); puts "yaml ok"', `.github/workflows/${file}`]);
    }
    for (const file of scope.changedFiles.filter((name) => /^ci\/.*\.js$/.test(name) && fs.existsSync(name))) {
      check(`JavaScript syntax ${file}`, "node", ["--check", file]);
    }
    const tests = relatedNodeTests(scope.changedFiles);
    if (tests.length) check("Changed CI helper regressions", "node", ["--test", ...tests]);
  }
  const repo = spawnSync("git", ["log", "-1", "--format=%H %s"], { encoding: "utf8" });
  fs.writeFileSync(`${directory}/repo-state.txt`, repo.stdout || repo.stderr || "unavailable");
  const manifest = writePackage(directory, scope, checks, env);
  process.exitCode = manifest.pipelineOutcome === "success" ? 0 : 1;
}

module.exports = { localLinkProblems, relatedNodeTests, writePackage };
if (require.main === module) main();
