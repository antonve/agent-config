---
name: reconcile
description: Process a pull request's complete review history through code changes, verification, push, replies, and accurate thread resolution. Use only when the user explicitly invokes $reconcile or /reconcile, or explicitly asks to reconcile or process existing pull request feedback; this is not a request to perform a new review.
---

# Reconcile pull request feedback

Close the loop between the pull request, its branch, and the current agent
thread. Every substantive feedback item must end with an explicit disposition,
and GitHub must describe code that is already present on the remote branch.

Do not merge the pull request, force-push, dismiss reviews, or expand the change
beyond the review without separate authorization. Follow the repository's
instructions for delivery, testing, comment signatures, and approvals.

## Establish the ledger

1. Identify the exact repository and pull request. Confirm its base, head
   repository, head branch, remote head commit, state, and whether the current
   worktree is safe to use. Check out or update the head branch without
   overwriting unrelated local work.
2. Fetch the complete, paginated GitHub record rather than trusting the pull
   request summary. Include:
   - every review thread and reply, including resolved, unresolved, outdated,
     and older threads;
   - submitted review bodies; and
   - pull request conversation comments.
3. Build a ledger with one row per substantive feedback item: stable ID or URL,
   author, source, current resolution state, requested outcome, related code,
   proposed disposition, implementation status, reply status, and final
   resolution state. Multiple comments in one thread may share one outcome,
   but none may disappear from the accounting.
4. Treat bot reports, duplicate restatements, and purely informational comments
   as accounted-for items with a recorded `no action` reason. Existing replies
   count only when they still accurately describe the current branch.

Use GitHub's GraphQL API when necessary because ordinary pull request views do
not expose the full review-thread resolution state. Use pagination and retain
node IDs needed to reply, resolve, or unresolve.

## Decide each outcome

Classify every substantive item before posting to GitHub:

- **addressed**: implement and verify it; resolve its review thread after the
  pushed code and reply are visible.
- **answered**: no code is needed and the answer conclusively settles the
  feedback; reply, then resolve only if no decision remains open.
- **partially addressed**: push the completed portion, state the remaining
  decision briefly, and leave the thread unresolved.
- **needs discussion**: do not conduct the detailed debate on GitHub. Leave a
  short trail that the point is being discussed in the agent thread, keep the
  GitHub thread unresolved, and bring the decision to the user here.
- **declined or blocked**: state the reason or blocker concisely and leave the
  thread unresolved unless the reviewer or user has explicitly settled it.

Resolution reflects reality, not optimism. Unresolve a previously resolved
thread if the branch no longer satisfies it. Do not resolve a thread merely
because it is outdated, acknowledged, or answered with a plan for future work.

## Change and verify the branch

1. Group compatible feedback into the smallest coherent edits. Check for
   interactions and contradictions across the entire ledger before changing
   code. Bring product or architecture choices to the user rather than choosing
   through a long GitHub exchange.
2. Implement authorized changes and verify them according to the repository's
   rules and the affected user workflow. A reply saying “fixed” requires
   evidence that the requested behavior is actually present.
3. Review the final diff against every ledger item. Commit and push normally to
   the pull request's exact head branch. Never force-push as part of this skill.
4. Re-fetch the pull request after the push. Confirm GitHub's head commit equals
   the local tested commit and add any feedback that arrived while editing to
   the ledger. Process those new items before claiming completion.

## Reply only after delivery

The ordering invariant is: **change → verify → commit → push → confirm remote
head → reply → resolve**. Never post a completion reply while its code exists
only locally. If a later edit is needed, push and confirm that edit before
replying about it.

Reply at the narrowest available location, normally in the originating review
thread. State what changed, where useful identify the pushed commit, and name
the relevant verification. Keep the message factual and brief. Apply any
repository-required signature or footer to every GitHub comment.

For an item that needs discussion, leave only a compact handoff such as:
“This remains open; I’m taking the product decision back to the agent thread
before changing the branch.” Put the actual options, evidence, and question in
the current agent conversation.

After replying, resolve only threads classified as addressed or conclusively
answered. Conversation comments and review bodies do not have a resolvable
thread state; their ledger disposition and response are their closure record.

## Final reconciliation

Re-fetch all comments and thread states once more. Do not finish while a
substantive item lacks a disposition, a promised reply is absent, a resolved
thread is known to remain unsatisfied, or GitHub's head differs from the tested
commit.

Report in the current agent thread:

- the pushed head commit and verification performed;
- which items were addressed and resolved;
- which items remain unresolved and why;
- which informational items required no action; and
- any decision the user still needs to make.

If permissions, authentication, branch ownership, failing required checks, or
an unresolved user decision prevents completion, preserve the accurate GitHub
state and report the precise blocker. Do not manufacture closure.
