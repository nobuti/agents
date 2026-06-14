const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const {
  assignInvocationNames,
  buildInvocationPrompt,
  discoverClaudeCommands,
  expandClaudeCommandArguments,
  parseClaudeCommandFile,
  parseNpmPackageName,
  resolvePackageRoot,
} = require("../pi-extensions/claude-commands/loader.js");

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "claude-commands-test-"));
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2));
}

function writeText(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, value);
}

test("parseNpmPackageName handles scoped and versioned specs", () => {
  assert.equal(parseNpmPackageName("npm:pi-subagents"), "pi-subagents");
  assert.equal(parseNpmPackageName("npm:pi-subagents@1.2.3"), "pi-subagents");
  assert.equal(parseNpmPackageName("npm:@scope/pkg@9.9.9"), "@scope/pkg");
});

test("resolvePackageRoot maps npm, git, and local specs to pi install roots", () => {
  const piDir = "/tmp/pi-root";
  const settingsDir = "/tmp/settings";

  assert.equal(
    resolvePackageRoot("npm:@scope/pkg@1.0.0", { piDir, settingsDir }),
    "/tmp/pi-root/npm/node_modules/@scope/pkg",
  );

  assert.equal(
    resolvePackageRoot("git:github.com/addyosmani/agent-skills@v1", { piDir, settingsDir }),
    "/tmp/pi-root/git/github.com/addyosmani/agent-skills",
  );

  assert.equal(
    resolvePackageRoot("./vendor/skills", { piDir, settingsDir }),
    "/tmp/settings/vendor/skills",
  );
});

test("parseClaudeCommandFile reads frontmatter description and markdown body", () => {
  const parsed = parseClaudeCommandFile(
    "---\ndescription: Example description\n---\n\nInvoke the agent-skills:test-driven-development skill.\n",
    "/tmp/build.md",
  );

  assert.equal(parsed.name, "build");
  assert.equal(parsed.description, "Example description");
  assert.equal(parsed.prompt, "Invoke the agent-skills:test-driven-development skill.");
});

test("expandClaudeCommandArguments supports all-args, positionals, defaults, and slices", () => {
  const template = [
    "all=$ARGUMENTS",
    "first=$1",
    "second=${2:-fallback}",
    "tail=${@:2}",
    "pair=${@:1:2}",
  ].join("\n");

  const expanded = expandClaudeCommandArguments(template, 'alpha "beta gamma"');

  assert.equal(
    expanded,
    [
      "all=alpha \"beta gamma\"",
      "first=alpha",
      "second=beta gamma",
      "tail=beta gamma",
      "pair=alpha beta gamma",
    ].join("\n"),
  );
});

test("discoverClaudeCommands reads plugin command directories from installed packages", () => {
  const root = makeTempDir();
  const globalPiDir = path.join(root, ".pi", "agent");
  const packageRoot = path.join(globalPiDir, "git", "github.com", "addyosmani", "agent-skills");

  writeJson(path.join(globalPiDir, "settings.json"), {
    packages: ["git:github.com/addyosmani/agent-skills", "npm:pi-subagents"],
  });
  writeJson(path.join(packageRoot, ".claude-plugin", "plugin.json"), {
    name: "agent-skills",
    commands: "./.claude/commands",
  });
  writeText(
    path.join(packageRoot, ".claude", "commands", "ship.md"),
    "---\ndescription: Ship it\n---\n\nInvoke the agent-skills:shipping-and-launch skill.\n",
  );
  writeJson(path.join(globalPiDir, "npm", "node_modules", "pi-subagents", "package.json"), {
    name: "pi-subagents",
  });

  const commands = discoverClaudeCommands({
    cwd: root,
    globalPiDir,
    projectTrusted: false,
  });

  assert.equal(commands.length, 1);
  assert.equal(commands[0].name, "ship");
  assert.equal(commands[0].packageName, "agent-skills");
  assert.equal(commands[0].scope, "user");
});

test("project package commands are discovered before global duplicates", () => {
  const root = makeTempDir();
  const globalPiDir = path.join(root, ".pi-global");
  const projectRoot = path.join(root, "project");
  const projectPiDir = path.join(projectRoot, ".pi");
  const localPackage = path.join(projectRoot, "vendor", "agent-skills-local");

  writeJson(path.join(globalPiDir, "settings.json"), {
    packages: ["git:github.com/addyosmani/agent-skills"],
  });
  writeJson(path.join(globalPiDir, "git", "github.com", "addyosmani", "agent-skills", ".claude-plugin", "plugin.json"), {
    name: "agent-skills",
    commands: "./.claude/commands",
  });
  writeText(
    path.join(globalPiDir, "git", "github.com", "addyosmani", "agent-skills", ".claude", "commands", "review.md"),
    "---\ndescription: Global review\n---\n\nGlobal command\n",
  );

  writeJson(path.join(projectPiDir, "settings.json"), {
    packages: ["../vendor/agent-skills-local"],
  });
  writeJson(path.join(localPackage, ".claude-plugin", "plugin.json"), {
    name: "agent-skills",
    commands: "./.claude/commands",
  });
  writeText(
    path.join(localPackage, ".claude", "commands", "review.md"),
    "---\ndescription: Project review\n---\n\nProject command\n",
  );

  const commands = discoverClaudeCommands({
    cwd: projectRoot,
    globalPiDir,
    projectTrusted: true,
  });

  assert.equal(commands.length, 2);
  assert.deepEqual(
    commands.map((command) => `${command.scope}:${command.description}`),
    ["project:Project review", "user:Global review"],
  );
});

test("assignInvocationNames keeps first command direct and aliases collisions", () => {
  const commands = assignInvocationNames([
    { name: "ship", packageName: "agent-skills" },
    { name: "ship", packageName: "custom-tools" },
  ]);

  assert.deepEqual(
    commands.map((command) => command.invocationName),
    ["ship", "ship-custom-tools"],
  );
});

test("buildInvocationPrompt wraps command for pi and strips package-prefixed skill references", () => {
  const prompt = buildInvocationPrompt(
    {
      name: "ship",
      packageName: "agent-skills",
      prompt: "Invoke the agent-skills:shipping-and-launch skill.",
    },
    "auto",
    { activeToolNames: ["read", "bash", "subagent"] },
  );

  assert.match(prompt, /Imported Claude-compatible command invoked: \/ship auto/);
  assert.match(prompt, /Prefer pi-native equivalents when helpful, including the active subagent tool/);
  assert.doesNotMatch(prompt, /agent-skills:shipping-and-launch/);
  assert.match(prompt, /Invoke the shipping-and-launch skill\./);
});
