const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const DEFAULT_GLOBAL_PI_DIR = process.env.PI_CODING_AGENT_DIR
  ? path.resolve(process.env.PI_CODING_AGENT_DIR)
  : path.join(os.homedir(), ".pi", "agent");

function expandHome(inputPath) {
  if (!inputPath) return inputPath;
  if (inputPath === "~") return os.homedir();
  if (inputPath.startsWith("~/")) return path.join(os.homedir(), inputPath.slice(2));
  return inputPath;
}

function readJsonFile(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function fileExists(targetPath) {
  try {
    fs.accessSync(targetPath);
    return true;
  } catch {
    return false;
  }
}

function findNearestPiDir(cwd) {
  let current = path.resolve(cwd);
  while (true) {
    const candidate = path.join(current, ".pi");
    if (fileExists(candidate)) return candidate;
    const parent = path.dirname(current);
    if (parent === current) return null;
    current = parent;
  }
}

function parseSettingsPackages(settingsFile) {
  const settings = readJsonFile(settingsFile);
  if (!settings || !Array.isArray(settings.packages)) return [];
  return settings.packages
    .map((entry) => {
      if (typeof entry === "string") return { source: entry };
      if (entry && typeof entry.source === "string") return { source: entry.source };
      return null;
    })
    .filter(Boolean);
}

function normalizeGitRepoSpec(source) {
  let spec = source.startsWith("git:") ? source.slice(4) : source;

  if (/^(https?|ssh|git):\/\//.test(spec)) {
    const url = new URL(spec);
    const host = url.hostname.toLowerCase();
    const repoPath = stripGitRef(url.pathname.replace(/^\//, "")).replace(/\.git$/, "");
    return repoPath ? { host, repoPath } : null;
  }

  const sshMatch = spec.match(/^git@([^:]+):(.+)$/);
  if (sshMatch) {
    return {
      host: sshMatch[1].toLowerCase(),
      repoPath: stripGitRef(sshMatch[2]).replace(/\.git$/, ""),
    };
  }

  const shorthandMatch = spec.match(/^([^/]+)\/(.+)$/);
  if (shorthandMatch) {
    return {
      host: shorthandMatch[1].toLowerCase(),
      repoPath: stripGitRef(shorthandMatch[2]).replace(/\.git$/, ""),
    };
  }

  return null;
}

function stripGitRef(repoPath) {
  const segments = repoPath.split("/");
  if (segments.length === 0) return repoPath;
  const last = segments[segments.length - 1];
  const atIndex = last.lastIndexOf("@");
  if (atIndex > 0) {
    segments[segments.length - 1] = last.slice(0, atIndex);
  }
  return segments.join("/");
}

function parseNpmPackageName(source) {
  if (!source.startsWith("npm:")) return null;
  const spec = source.slice(4);
  if (!spec) return null;

  if (spec.startsWith("@")) {
    const slashIndex = spec.indexOf("/");
    if (slashIndex === -1) return spec;
    const versionIndex = spec.indexOf("@", slashIndex + 1);
    return versionIndex === -1 ? spec : spec.slice(0, versionIndex);
  }

  const versionIndex = spec.indexOf("@");
  return versionIndex === -1 ? spec : spec.slice(0, versionIndex);
}

function isLocalPackageSource(source) {
  return (
    source.startsWith("/") ||
    source.startsWith("./") ||
    source.startsWith("../") ||
    source.startsWith("~/") ||
    source === "~"
  );
}

function resolvePackageRoot(source, options = {}) {
  const settingsDir = options.settingsDir ? path.resolve(options.settingsDir) : DEFAULT_GLOBAL_PI_DIR;
  const piDir = options.piDir ? path.resolve(options.piDir) : DEFAULT_GLOBAL_PI_DIR;

  if (isLocalPackageSource(source)) {
    return path.resolve(settingsDir, expandHome(source));
  }

  const npmPackageName = parseNpmPackageName(source);
  if (npmPackageName) {
    return path.join(piDir, "npm", "node_modules", npmPackageName);
  }

  const gitRepo = normalizeGitRepoSpec(source);
  if (gitRepo) {
    return path.join(piDir, "git", gitRepo.host, gitRepo.repoPath);
  }

  return null;
}

function getPackageIdentity(source, options = {}) {
  if (isLocalPackageSource(source)) {
    return `local:${path.resolve(options.settingsDir || process.cwd(), expandHome(source))}`;
  }

  const npmPackageName = parseNpmPackageName(source);
  if (npmPackageName) return `npm:${npmPackageName}`;

  const gitRepo = normalizeGitRepoSpec(source);
  if (gitRepo) return `git:${gitRepo.host}/${gitRepo.repoPath}`;

  return `raw:${source}`;
}

function collectPackageSpecs(options = {}) {
  const cwd = path.resolve(options.cwd || process.cwd());
  const globalPiDir = path.resolve(options.globalPiDir || DEFAULT_GLOBAL_PI_DIR);
  const projectTrusted = Boolean(options.projectTrusted);
  const specs = [];

  const projectPiDir = projectTrusted ? findNearestPiDir(cwd) : null;
  if (projectPiDir) {
    const settingsFile = path.join(projectPiDir, "settings.json");
    for (const entry of parseSettingsPackages(settingsFile)) {
      specs.push({
        ...entry,
        scope: "project",
        settingsFile,
        settingsDir: path.dirname(settingsFile),
        piDir: projectPiDir,
      });
    }
  }

  const globalSettingsFile = path.join(globalPiDir, "settings.json");
  for (const entry of parseSettingsPackages(globalSettingsFile)) {
    specs.push({
      ...entry,
      scope: "user",
      settingsFile: globalSettingsFile,
      settingsDir: path.dirname(globalSettingsFile),
      piDir: globalPiDir,
    });
  }

  const deduped = [];
  const seen = new Set();
  for (const spec of specs) {
    const identity = getPackageIdentity(spec.source, { settingsDir: spec.settingsDir });
    if (seen.has(identity)) continue;
    seen.add(identity);
    deduped.push({ ...spec, identity });
  }

  return deduped;
}

function parseFrontmatter(markdown) {
  const normalized = markdown.replace(/\r\n/g, "\n");
  if (!normalized.startsWith("---\n")) {
    return { attributes: {}, body: normalized.trim() };
  }

  const lines = normalized.split("\n");
  const attributes = {};
  let index = 1;
  for (; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === "---") {
      index += 1;
      break;
    }
    const separatorIndex = line.indexOf(":");
    if (separatorIndex === -1) continue;
    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    attributes[key] = value;
  }

  return {
    attributes,
    body: lines.slice(index).join("\n").trim(),
  };
}

function parseClaudeCommandFile(markdown, filePath) {
  const { attributes, body } = parseFrontmatter(markdown);
  const description = attributes.description || firstNonEmptyLine(body) || `Imported Claude command: ${path.basename(filePath)}`;
  return {
    name: path.basename(filePath, path.extname(filePath)),
    description,
    prompt: body,
  };
}

function firstNonEmptyLine(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .find(Boolean);
}

function readPackageName(packageRoot) {
  const pluginManifest = readJsonFile(path.join(packageRoot, ".claude-plugin", "plugin.json"));
  if (pluginManifest && typeof pluginManifest.name === "string") return pluginManifest.name;

  const packageJson = readJsonFile(path.join(packageRoot, "package.json"));
  if (packageJson && typeof packageJson.name === "string") return packageJson.name;

  return path.basename(packageRoot);
}

function getClaudeCommandDirs(packageRoot) {
  const dirs = [];
  const pluginManifestPath = path.join(packageRoot, ".claude-plugin", "plugin.json");
  const pluginManifest = readJsonFile(pluginManifestPath);

  if (pluginManifest && typeof pluginManifest.commands === "string") {
    dirs.push(path.resolve(packageRoot, pluginManifest.commands));
  }

  const conventionalDir = path.join(packageRoot, ".claude", "commands");
  if (dirs.length === 0 && fileExists(conventionalDir)) {
    dirs.push(conventionalDir);
  }

  return dirs.filter((dir, index) => dirs.indexOf(dir) === index && fileExists(dir));
}

function discoverClaudeCommands(options = {}) {
  const commands = [];
  for (const spec of collectPackageSpecs(options)) {
    const packageRoot = resolvePackageRoot(spec.source, spec);
    if (!packageRoot || !fileExists(packageRoot)) continue;

    const packageName = readPackageName(packageRoot);
    const commandDirs = getClaudeCommandDirs(packageRoot);
    for (const commandDir of commandDirs) {
      const entries = fs.readdirSync(commandDir, { withFileTypes: true });
      for (const entry of entries) {
        if (!entry.isFile() || path.extname(entry.name) !== ".md") continue;
        const filePath = path.join(commandDir, entry.name);
        const parsed = parseClaudeCommandFile(fs.readFileSync(filePath, "utf8"), filePath);
        commands.push({
          ...parsed,
          packageName,
          packageRoot,
          packageSource: spec.source,
          scope: spec.scope,
          filePath,
        });
      }
    }
  }

  return commands;
}

function tokenizeArguments(rawArgs) {
  const tokens = [];
  let current = "";
  let quote = null;
  let escaping = false;

  for (const char of rawArgs.trim()) {
    if (escaping) {
      current += char;
      escaping = false;
      continue;
    }

    if (char === "\\") {
      escaping = true;
      continue;
    }

    if (quote) {
      if (char === quote) {
        quote = null;
      } else {
        current += char;
      }
      continue;
    }

    if (char === '"' || char === "'") {
      quote = char;
      continue;
    }

    if (/\s/.test(char)) {
      if (current) {
        tokens.push(current);
        current = "";
      }
      continue;
    }

    current += char;
  }

  if (current) tokens.push(current);
  return tokens;
}

function expandClaudeCommandArguments(template, rawArgs = "") {
  const trimmedArgs = rawArgs.trim();
  const tokens = tokenizeArguments(rawArgs);

  let result = template;

  result = result.replace(/\$\{@:(\d+):(\d+)\}/g, (_match, startText, lengthText) => {
    const start = Number(startText) - 1;
    const length = Number(lengthText);
    return tokens.slice(start, start + length).join(" ");
  });

  result = result.replace(/\$\{@:(\d+)\}/g, (_match, startText) => {
    const start = Number(startText) - 1;
    return tokens.slice(start).join(" ");
  });

  result = result.replace(/\$\{(\d+):-([^}]*)\}/g, (_match, indexText, defaultValue) => {
    const index = Number(indexText) - 1;
    return tokens[index] || defaultValue;
  });

  result = result.replace(/\$\{(\d+)\}/g, (_match, indexText) => {
    const index = Number(indexText) - 1;
    return tokens[index] || "";
  });

  result = result.replace(/\$ARGUMENTS\b/g, trimmedArgs);
  result = result.replace(/\$@\b/g, trimmedArgs);

  result = result.replace(/\$(\d+)/g, (_match, indexText) => {
    const index = Number(indexText) - 1;
    return tokens[index] || "";
  });

  return result;
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizePromptForPi(prompt, packageName) {
  let normalized = prompt.trim();
  if (packageName) {
    normalized = normalized.replace(new RegExp(`${escapeRegExp(packageName)}:`, "g"), "");
  }
  return normalized;
}

function buildInvocationPrompt(command, rawArgs = "", options = {}) {
  const expandedPrompt = expandClaudeCommandArguments(command.prompt, rawArgs);
  const normalizedPrompt = normalizePromptForPi(expandedPrompt, command.packageName);
  const activeToolNames = Array.isArray(options.activeToolNames) ? options.activeToolNames : [];
  const hasSubagentTool = activeToolNames.includes("subagent");
  const invocation = rawArgs.trim() ? `/${command.name} ${rawArgs.trim()}` : `/${command.name}`;

  const preface = [
    `Imported Claude-compatible command invoked: ${invocation}`,
    `Source package: ${command.packageName}`,
    "Execute this workflow faithfully in pi.",
    "Translation rules:",
    "- Preserve the command's intent, ordering, and acceptance criteria.",
    "- Treat Claude Code, Agent tool, plugins, and .claude paths as harness-specific examples, not hard requirements.",
    hasSubagentTool
      ? "- Prefer pi-native equivalents when helpful, including the active subagent tool for persona fan-out."
      : "- If the command relies on Claude-only fan-out and no equivalent tool is active, follow the fallback path described in the command.",
    "- Use installed pi skills, prompt templates, and extensions when they match the referenced workflow.",
    "- If a Claude-only primitive has no pi equivalent, say so briefly and continue with the closest faithful workflow.",
    "",
    normalizedPrompt,
  ];

  return preface.join("\n");
}

function slugify(value) {
  return value
    .toLowerCase()
    .replace(/^@/, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || "package";
}

function assignInvocationNames(commands) {
  const usedNames = new Set();
  return commands.map((command) => {
    let invocationName = command.name;
    if (usedNames.has(invocationName)) {
      invocationName = `${command.name}-${slugify(command.packageName)}`;
    }

    let suffix = 2;
    while (usedNames.has(invocationName)) {
      invocationName = `${command.name}-${slugify(command.packageName)}-${suffix}`;
      suffix += 1;
    }

    usedNames.add(invocationName);
    return { ...command, invocationName };
  });
}

module.exports = {
  DEFAULT_GLOBAL_PI_DIR,
  assignInvocationNames,
  buildInvocationPrompt,
  collectPackageSpecs,
  discoverClaudeCommands,
  expandClaudeCommandArguments,
  findNearestPiDir,
  getPackageIdentity,
  normalizeGitRepoSpec,
  parseClaudeCommandFile,
  parseNpmPackageName,
  resolvePackageRoot,
  tokenizeArguments,
};
