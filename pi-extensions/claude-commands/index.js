const {
  assignInvocationNames,
  buildInvocationPrompt,
  discoverClaudeCommands,
} = require("./loader.js");

module.exports = function claudeCommandsExtension(pi) {
  let registered = false;

  pi.on("session_start", async (_event, ctx) => {
    if (registered) return;
    registered = true;

    const commands = assignInvocationNames(
      discoverClaudeCommands({
        cwd: ctx.cwd,
        projectTrusted: ctx.isProjectTrusted(),
      }),
    );

    for (const command of commands) {
      pi.registerCommand(command.invocationName, {
        description: command.description,
        handler: async (args, commandCtx) => {
          const prompt = buildInvocationPrompt(command, args, {
            activeToolNames: pi.getActiveTools(),
          });

          if (commandCtx.isIdle()) {
            pi.sendUserMessage(prompt);
            return;
          }

          pi.sendUserMessage(prompt, { deliverAs: "followUp" });
          commandCtx.ui.notify(`Queued /${command.invocationName} as follow-up`, "info");
        },
      });
    }

    if (commands.length > 0) {
      const packageNames = [...new Set(commands.map((command) => command.packageName))];
      ctx.ui.notify(
        `Imported ${commands.length} Claude command${commands.length === 1 ? "" : "s"} from ${packageNames.length} package${packageNames.length === 1 ? "" : "s"}`,
        "info",
      );
    }
  });
};

module.exports.default = module.exports;
