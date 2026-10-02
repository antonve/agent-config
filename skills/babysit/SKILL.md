---
name: babysit
description: Watch an authorized pull request through CI, fix actionable failures on its branch, and squash merge it into main once every merge gate passes. Use when the user asks to babysit or land a PR; not for review-only requests.
---

# Babysit a pull request

Stay with the named PR until GitHub confirms its squash merge into `main`, or a concrete blocker requires the user's decision. An explicit request to babysit or land a PR authorizes its ordinary CI fixes, pushes, and squash merge. A mention of this skill or a request for CI status alone does not.

1. Identify the exact repository and PR. Confirm its base is `main`, it is open and ready for review, and record its head branch, repository, and SHA. Follow the repository's `AGENTS.md` and test instructions. Use a clean worktree for the PR head; preserve unrelated local changes.
2. Inspect all checks for the **current head SHA**, including required checks and any other applicable CI jobs. Treat pending or queued work as unfinished, failed, cancelled, or timed-out work as red, and skipped or neutral conclusions according to the repository's gate. Check review requirements and GitHub mergeability too. Keep the user informed when a check runs for an extended period.
3. If CI is red, read the failed job logs and relevant code to find the cause. Fix failures within the authorized PR scope, verify the affected workflow locally where practical, commit and push to that PR's branch, then watch the new head's checks. Do not count a stale green run from an earlier SHA. If the failure is flaky, rerun the affected job once with evidence before changing code. Follow newly arrived feedback and repository rules for review threads; do not mark threads resolved without a verified fix.
4. Repeat the inspect, fix, push, and wait loop until all applicable checks on the current head pass, required reviews are satisfied, and GitHub reports the PR mergeable. Recheck the PR's head and gates immediately before merging. Squash merge with `gh pr merge <number> --squash --match-head-commit <verified-head-sha>` when supported. Confirm the PR is merged into `main` and report the merge commit and checks.

Do not bypass branch protection, dismiss reviews, force-push, or merge while a check is missing, pending, failed, or cancelled. Stop with the precise blocker and evidence when a fix needs a product decision, new credentials, risky or out-of-scope changes, a rollback, unavailable CI, or permissions the user has not granted. Preserve the branch and report the next action needed; never call a blocked PR merged.
