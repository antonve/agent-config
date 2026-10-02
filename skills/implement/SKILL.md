---
name: implement
description: Orchestrate an implementation with a GPT-6 Sol high main loop, GPT-6 Astra high planning, parallel GPT-6 Sol high implementers with higher effort for complex tasks, and a dedicated GPT-6 Astra reviewer per implementer. Use only when the user explicitly invokes $implement, /implement, or asks to use the implement skill; never select it automatically for ordinary coding requests.
---

# Implement with paired agents

Activate only for an explicit user invocation. Keep this workflow scoped to
the requested task; it does not become a default for later unrelated work.

## Roles and routing

| Role | Model | Responsibility |
| --- | --- | --- |
| Coordinator / main loop | Current thread on `gpt-6-sol`, `reasoning_effort: "high"` | Inspect context, commission planning, assign ownership, coordinate feedback, integrate and verify delivery. |
| Planner | `gpt-6-astra`, `reasoning_effort: "high"` | Develop and revise the implementation plan, including dependencies, ownership, acceptance criteria, and gates. |
| Implementer | `gpt-6-sol`, `reasoning_effort: "high"` (`"xhigh"` for complex tasks) | Implement an assigned work package, verify it, and fix review findings. |
| Paired reviewer | `gpt-6-astra`, `reasoning_effort: "xhigh"` | Independently review that implementer's changes and verify corrections. |

Start the coordinator thread on Sol 6 high. Loading this skill does not change
an already-running thread's model or reasoning effort; if either differs, ask
the user to select Sol 6 high or explicitly choose different routing before
dispatching agents.

Use the available collaboration tools. When spawning with model overrides,
set `fork_turns: "none"` and put the necessary context in the task message;
a full-history fork inherits the parent's model and cannot take overrides.
Set Sol implementers' reasoning effort explicitly to `"high"` by default.
Use `"xhigh"` for complex work packages. Honor an explicit user override.
If the required models or delegation tools are unavailable, report that
limitation and ask for a routing decision instead of silently substituting.

The coordinator owns agent creation and delivery. Planners, workers, and
reviewers must not recursively invoke this skill, spawn their own teams, or
independently commit, push, merge, publish, or deploy. Existing user
authorization and repository instructions still govern those actions in the
coordinator.

## Plan with Astra high

1. Inspect the request, applicable repository instructions, existing changes,
   and relevant implementation. Define observable acceptance criteria and
   the verification needed to establish them.
2. Spawn an Astra planner with `model: "gpt-6-astra"` and
   `reasoning_effort: "high"`. Give it the request, repository context,
   constraints, and verification requirements. Have it inspect the relevant
   code and return a plan with dependencies, file ownership, and completion
   gates. The planner is read-only with respect to implementation files.
   The coordinator reconciles the plan with the user's requirements and
   follows the repository's planning and publication conventions.
3. Split independent work into bounded packages. Parallelize packages whose
   edits and dependencies do not conflict. Give shared interfaces and files
   one owner, or serialize their changes. Use one pair when the task cannot
   usefully be split; do not invent work just to increase agent count.
4. Track each package's implementer, paired reviewer, owned paths, acceptance
   criteria, current change snapshot, checks, and unresolved findings. Budget
   concurrency for both roles; queue packages when agent slots are limited.

## Dispatch and review

For each ready package, spawn a Sol implementer with the exact repository or
worktree path, relevant instructions, scope and exclusions, owned files,
dependencies/interface contracts, acceptance criteria, and verification
commands. Explain that other agents share the filesystem: preserve their work
and request coordination before touching another owner's files. Require a
handoff with changed paths, a reproducible diff or snapshot, check commands and
results, and remaining risks. Follow the repository's test-first rules where
applicable; do not invent unit tests that only restate the implementation.

Assign a dedicated Astra reviewer to each implementer. Start the reviewer when
there is useful independent work, such as examining acceptance criteria and
existing behavior; otherwise spawn it when the first handoff is ready. Give it
the task's original requirements, relevant instructions, owned paths, exact
change snapshot, and verification evidence. Reviewers are read-only with
respect to implementation files and independently inspect code and behavior;
the implementer's summary is not sufficient evidence.

Use this loop until the package meets its acceptance criteria:

1. Have the implementer pause writes to the reviewed paths and hand off a
   stable snapshot. Have the paired reviewer check correctness, missing
   requirements, regressions, maintainability, and verification gaps.
2. Require either **approved** for the identified snapshot with supporting
   checks, or **changes requested** with concrete locations, impact, and
   actionable findings. Distinguish blocking findings from optional polish.
3. Route blocking findings to the same Sol implementer. Resume an idle agent
   with the follow-up task tool; use messages for agents still running.
4. Send the revised snapshot and check results back to the same Astra reviewer.
   Track every blocking finding to a verified fix or an explicit coordinator
   decision supported by evidence. A rejected finding must be reconciled with
   the reviewer; do not count disputed work as approved.

Keep unrelated pairs moving while one pair iterates. Return to the Astra high
planner when dependencies or product and architecture decisions require a
revised plan. Escalate a concrete blocker or repeated disagreement to the
current thread instead of creating endless retries or replacing a reviewer to
obtain approval. Ask the user only when a missing decision or authorization
requires them; review alone does not authorize new scope or external actions.

## Integrate and finish

After the packages pass review, verify the combined result through the real
user or system workflow and the repository's required checks. Delegate any
integration fixes to Sol and route them through its paired Astra reviewer.
Have an Astra reviewer inspect the combined diff for cross-package regressions
and confirm the final snapshot; package approvals alone are not an integration
gate. Any later code changes require review of the affected scope again.

Complete authorized repository delivery from this thread. Report what shipped,
the verification evidence, and any remaining blocker or unverified boundary.
Do not claim satisfactory completion while blocking findings, required checks,
or requested delivery steps remain unresolved.
