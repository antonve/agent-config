---
name: restate
description: Restate in your own words what the user's goals are and what problem they are trying to solve, then stop for confirmation. Use only when the user explicitly invokes $restate or /restate.
disable-model-invocation: true
---

# Restate the goals and problem

Adapted from Lauren Tan's (@poteto) prompt: "restate in your own words what you
think my goals are and what the problem i'm trying to solve is".

Before doing more work, show the user how you understand the task so they can
correct misunderstandings early. Base the restatement on the whole conversation
and any context you have already read. If something is unclear, read relevant
code or files first, but do not start implementing or change anything.

Reply in your own words, without repeating the user's phrasing:

- **Goals:** the outcomes the user wants and why they matter.
- **Problem:** what currently blocks or fails, and its root cause if known.
- **Constraints and non-goals:** the explicit or implied limits.
- **Assumptions and open questions:** what you inferred and what is still
  ambiguous, with the most decision-relevant item first.

Keep it short. Then stop and ask the user to confirm or correct it. Do not
continue with the task until they reply.
