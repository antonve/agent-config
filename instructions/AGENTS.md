# Planning work

- Never suggest migration or task timelines, completion dates, ETAs, or time-based effort estimates (hours, days, or weeks). Describe scope, dependencies, risks, phases, and completion gates instead.
- Publish every user-facing planning artifact to Draft; the agent is already authenticated. Default to a self-contained, responsive HTML document using the restrained editorial style below, including for implementation plans, findings reports, PRDs, and ideation. Use Markdown only when the user explicitly requests it, when revising an existing Markdown artifact in place, or when a concrete compatibility constraint requires it; state that constraint when it applies.

## Document formatting

- Prioritize readable typography and information hierarchy: clear heading levels, comfortable body text and line spacing, bounded paragraph widths, and consistent spacing. Readability and consistency take precedence over visual novelty.
- Put the main finding, recommendation, or decision near the beginning, then develop the supporting detail in a continuous reading flow. Organize content with headings, whitespace, and subtle dividers.
- Keep decorative styling minimal. Use color and callouts to mark meaningful recommendations, risks, or gates; tables for comparisons; checklists for actionable steps; and diagrams when they clarify relationships. Avoid unnecessary cards, badges, oversized hero sections, gradients, and animation.
- Allow fonts, colors, and section layouts to suit the content while preserving clear typography, hierarchy, reading flow, and restraint.

## Implementation plans

- Include an overview, risks and benefits, and measurable success criteria.
- Organize the work into phases. Each phase needs a checkbox checklist detailed enough for an agent with no prior context to execute, followed by a gate that must pass before the next phase starts.
- Separate independent work so subagents can execute it in parallel.
- End with follow-up improvements or ideas that the completed work makes possible.

## Reports

- Optimize for learning and fast scanning with clear typography. Use Mermaid diagrams and relevant tables, data, or images to make material findings easy to understand.

## Product requirements documents

- Describe the problem and the feature's intended behavior and appearance; do not prescribe its implementation. Compare viable solutions and state the chosen product direction.

## GitHub pull requests

- Open new pull requests as ready for review, not as drafts, unless the user explicitly requests a draft PR.

## GitHub comments

- End every comment you post on GitHub with the following signature on its own line, separated from the preceding content by a blank line: `**Posted by $model**`. Replace `$model` with the exact model name used to author the comment.
- Keep screenshots created solely as PR review evidence out of source commits. Use a supported attachment or artifact path; if that is unavailable, retain the captures and state the limitation rather than claiming the requested screenshots were delivered.
- When asked to address PR review, track every applicable unresolved thread, including older or outdated threads, to a fix or explicit remaining decision. When replies are requested, reply in the originating threads and re-fetch before reporting the review complete. An advice-only request does not authorize implementation or posting replies.

## Testing

- Never write unit tests after implementing the code they cover. If a component must be tested in isolation, first enumerate its failure modes and write the tests, then implement or change the code.
- Strongly prefer E2E tests as the sole testing mechanism. Verify complex features through real user or system workflows. Do not add unit-test suites merely to accompany implementation or assertions that only restate constants, mirror implementation details, or validate mocked behavior.
- E2E verification must produce an inspectable artifact and be repeatable. Record the command, setup or fixtures, tested revision, and result; retain a suitable report, trace, or output artifact, and identify any mocked or unverified boundaries.

## Completion and verification

- Before finishing, reconcile the original request and subsequent corrections with the delivered result. Complete remaining authorized steps; identify any unfinished requirement and its blocker. Keep reporting concise without reducing the work.
- Verify the result through the interface the user will use. For UI changes, inspect the rendered page and exercise affected interactions and relevant states. Report unavailable verification explicitly. Match checks to the change and rerun when new changes or failures justify it.
- For performance changes, establish a representative baseline, locate the bottleneck, and compare equivalent workloads afterward. Report measurements and tradeoffs; preserve required behavior.

## Shared development processes

- Before starting a development server, check for a healthy instance belonging to the exact project or worktree. Verify process ownership before stopping anything; never terminate processes through broad name matching. Follow the environment’s port and preview conventions.

## Scratch files on T3 Code hosts

- Put temporary evidence, logs, downloads and throwaway checkouts under `/workspace/.scratch/<task>` or `/cache/.scratch/<task>`, never as new top-level entries in `/workspace` or `/cache`. Entries there older than 10 days are deleted automatically, so move anything worth keeping into a repository or Draft.

## Regression evidence

- When claiming a regression test fails before a fix, verify that it compiles against the pre-fix behavior and fails for the intended behavioral reason. A compiler/API mismatch or unrelated timeout is not regression evidence.

## Rollbacks and costly reversals

- Get the user's explicit permission before performing a rollback or reversal that is not urgently required to contain active harm and would materially consume tokens, compute, or operator time; discard or undo implemented work; or change a live service. A failed gate or a rollback step written into an approved plan is not standing authorization for such an action. Stop, report the evidence, expected cost and impact, and available alternatives, then wait for permission. If immediate action is necessary to prevent ongoing data loss, security exposure, or service damage, apply only the minimum safe containment and notify the user promptly.

## TrueNAS browser operations

- The TrueNAS web UI is slow and can briefly flash the login screen while an authenticated route is loading. Do not interpret that transient screen as a lost session.
- Never perform back-to-back TrueNAS browser actions. After every navigation, click, form entry, or submission, explicitly wait for the expected URL, text, or element to finish loading before inspecting the page or taking the next action.
- If TrueNAS appears stuck or shows the login screen unexpectedly, refresh the current page and wait for it to settle before diagnosing a blocker. Treat authentication as lost only when the login screen persists after that refresh-and-wait check; do not ask the user to intervene for ordinary transient UI behavior.
