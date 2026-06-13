// Deep-research-codebase orchestration template.
//
// The scaled-up form of the /deep-research-codebase method: parallel survey
// (one Explore agent per angle) -> adversarial verify (pipeline, no barrier)
// -> cited synthesis. Mirrors the bundled /deep-research workflow, but every
// source is a file in the CURRENT repo and every claim resolves to file:line.
//
// Requires explicit user opt-in (Workflow tool: "use a workflow" / ultracode).
//
// Pass the scoped question + the angles you decomposed during Scope as args:
//   Workflow({ scriptPath: "<this file>", args: { question, angles } })
// args.angles is optional — a sensible default set is used when omitted.

export const meta = {
  name: "deep-research-codebase",
  description: "Deep, citation-verified, multi-angle research over the current codebase",
  phases: [
    { title: "Survey", detail: "One read-only Explore agent per angle, in parallel" },
    { title: "Verify", detail: "Adversarially re-check each claim against the cited file:line" },
    { title: "Synthesize", detail: "Merge dupes, rank by confidence, write the cited report" },
  ],
};

const question =
  args?.question ?? "Describe how this codebase is structured and how its core flow works.";

const angles = args?.angles ?? [
  "Entry points and top-level structure",
  "Core domain model and key abstractions",
  "Primary data and control flow for the main feature",
  "Configuration, feature flags, and environment coupling",
  "Tests and what behaviour they pin down",
];

const FINDINGS = {
  type: "object",
  properties: {
    findings: {
      type: "array",
      items: {
        type: "object",
        properties: {
          claim: { type: "string", description: "A single falsifiable statement about the code" },
          evidence: { type: "string", description: "Exact file:line plus a short verbatim quote" },
          confidence: { type: "string", enum: ["high", "medium", "low"] },
        },
        required: ["claim", "evidence", "confidence"],
      },
    },
  },
  required: ["findings"],
};

const VERDICT = {
  type: "object",
  properties: {
    holds: {
      type: "boolean",
      description: "True only if the cited source genuinely supports the claim",
    },
    reason: { type: "string" },
    correctedEvidence: {
      type: "string",
      description: "Tighter file:line if the original was close but imprecise",
    },
  },
  required: ["holds", "reason"],
};

phase("Survey");

// Survey each angle, then verify its findings as soon as the angle returns —
// no barrier between phases (a slow angle never blocks a fast angle's verify).
const surveyed = await pipeline(
  angles,
  (angle) =>
    agent(
      `Research angle for the question "${question}": ${angle}.\n` +
        `Investigate ONLY the current repository. Use Grep/Glob/Read. Read-only — never edit.\n` +
        `Return falsifiable findings. EVERY finding MUST cite an exact file:line and a short ` +
        `verbatim quote from that location. Drop any claim you cannot cite — do not soften it.`,
      {
        label: `survey:${angle.slice(0, 28)}`,
        phase: "Survey",
        schema: FINDINGS,
        agentType: "Explore",
      }
    ),
  (result, angle) =>
    parallel(
      (result?.findings ?? []).map(
        (f) => () =>
          agent(
            `Adversarially verify this claim about the codebase. Open the cited source and check it ` +
              `actually says what is claimed. Default to holds=false if the citation is vague, missing, ` +
              `stale, or does not support the claim.\n\n` +
              `Claim: ${f.claim}\nCited evidence: ${f.evidence}`,
            { label: "verify", phase: "Verify", schema: VERDICT }
          ).then((v) => ({ ...f, angle, verdict: v }))
      )
    )
);

const confirmed = surveyed
  .flat()
  .filter(Boolean)
  .filter((f) => f.verdict?.holds)
  .map((f) => ({ ...f, evidence: f.verdict?.correctedEvidence || f.evidence }));

log(`${confirmed.length} verified findings across ${angles.length} angles`);

phase("Synthesize");

const report = await agent(
  `Synthesize a cited research report answering: "${question}".\n` +
    `Use ONLY these verified findings. Merge duplicates, rank by confidence, and keep every ` +
    `file:line citation. Note open questions for any angle that produced no verified findings.\n\n` +
    `Report shape: a direct 2–4 sentence Answer, then Findings (claim + file:line + quote + ` +
    `confidence), an optional text Map of the flow, then Open questions.\n\n` +
    JSON.stringify(confirmed, null, 2),
  { phase: "Synthesize" }
);

return { question, angles, confirmedCount: confirmed.length, report };
