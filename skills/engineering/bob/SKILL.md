---
name: bob
description: Router for the engineering skills. Proposes a playbook for your request, runs it step by step with evidence, and sets up per-repo config (`/bob setup`).
argument-hint: "[setup | what you want to do]"
disable-model-invocation: true
---

# Bob

Proxy router. Every step below is mandatory and visible: announce each as you do it.

No request given? Ask one line: "What do you want to do?" Do not list skills.

## Procedure

1. **Resolve `<root>`** per [CONFIG.md](CONFIG.md). If `/bob setup` was requested, or `<root>/config.md` is missing, run [SETUP.md](SETUP.md) first, then continue. Evidence: print `<root>` and whether `config.md` was read, created, or fell back to `default/`.
2. **Read [FLOWS.md](FLOWS.md).** Evidence: name the flow you will follow.
3. **Classify and propose.** Match the request to one playbook in [playbooks/](playbooks/): [feature](playbooks/feature.md), [bug](playbooks/bug.md), [triage](playbooks/triage.md), [wayfinder](playbooks/wayfinder.md), [architecture](playbooks/architecture.md), [research](playbooks/research.md), [review](playbooks/review.md), [quick](playbooks/quick.md). Read the chosen file, then PROPOSE: playbook name, why, the task list. WAIT for the user's confirmation. Ambiguous: name the two best candidates and ask.
4. **Load the task list.** After confirmation, copy the playbook's steps verbatim into the task list (TodoWrite). A skipped step stays visible with a one-line reason; never drop or reorder silently.
5. **Execute.** Invoke each step's skill with the Skill tool. Delegate by role per [models.md](models.md). Mark a step done only after its output exists.
6. **Evidence gate.** Before reporting success, show per success criterion of the playbook its proof: command run plus output, file read, or test result. A claim without a run or read is labelled "Unverified".
7. **Sticky.** Follow-up messages stay in the current playbook until the user says "new task"; then go to step 3.

## Failure modes

| Temptation | Required instead |
| --- | --- |
| "The playbook is obvious, skip the proposal" | Propose and wait for confirmation |
| "Step is irrelevant, drop it" | Keep it visible with a one-line reason |
| "The subagent said tests pass" | Run them and show the output |
| "Done, looks right" | Show per-criterion evidence or label "Unverified" |
| "I'll just fix it myself" | Delegate implementation per models.md unless trivial |
| "New topic, same playbook" | Ask for "new task" and re-classify |
