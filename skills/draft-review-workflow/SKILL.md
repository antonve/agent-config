---
name: draft-review-workflow
description: Publish, revise, or publicly share Draft HTML or Markdown documents. Use when Codex needs to put a document in Draft for review, work through its durable human-annotation loop, recover an interrupted review, or publish a pinned Draft HTML revision through an unlisted GitHub Gist and return an HTMLPreview link.
---

# Work with Draft documents

Use the `draft` CLI as the durable handoff between the agent and reviewer.

## Start or update a document

1. Verify `command -v draft` and `draft auth status`. If authentication is
   absent, run `draft auth login` and let the user complete the device flow.
2. Keep an editable source file. Prefer a self-contained HTML artifact unless
   the user requests Markdown or an existing artifact fixes the format.
3. Choose a stable slug. Before updating an existing slug, identify its current
   version and fetch that revision when the local source is not known to match.
4. Create a new document and capture its JSON result:

   ```sh
   draft publish <file> --slug <slug> --title <title> \
     --client-label agent-review --json
   ```

5. Update a document only from the exact revision used as the editing base:

   ```sh
   draft publish <file> --slug <slug> --base-version <version> \
     --client-label agent-review --json
   ```

   Never retry a `stale_base` failure with the newly reported version. Fetch
   that revision with `draft get <slug> --version <version>`, reconcile it with
   the edited source, and publish the reconciled result from that version.
6. Return the pinned URL returned by `draft publish`. Publishing alone does
   not require waiting for feedback. When review is requested, explain that
   the user can open Review, annotate elements or selected text, add general
   notes, and choose **Send feedback to agent**.
7. Before presenting a document as completion evidence, check that its pinned
   revision reflects the final results. If later work changed those results,
   publish an update from the exact base revision or explicitly label the
   earlier evidence as historical.

## Receive and apply feedback

Enter this loop when the user requests a review or asks you to process
feedback for the document.

1. Before blocking, tell the user that Draft is waiting for their submitted
   review. Then use the CLI's bounded long-poll loop:

   ```sh
   draft feedback wait --slug <slug> --json
   ```

   Let the process wait in a resumable execution session. Do not replace it
   with rapid list polling. Its waiting notice goes to stderr and the complete
   review JSON goes to stdout.
2. Record the review `id`, `document_version`, `latest_version`, `content_hash`,
   comments, and anchors. Reading marks the review observed but does not consume
   it; it remains pending until resolution.
3. Apply every comment against `document_version`, not an unpinned latest view.
   Use the local source only when it is known to represent that exact content;
   otherwise recover it with:

   ```sh
   draft get <slug> --version <document-version> > <source-file>
   ```

   Use each anchor's quote, offsets, rendered path, and surrounding context as
   redundant evidence. Treat the quoted text and the comment's intent as
   authoritative when DOM structure has shifted.
4. If `latest_version` advanced beyond the reviewed version, reconcile the
   latest revision before publishing. Do not overwrite concurrent work.
5. Validate the edited artifact, publish it from its exact base version, and
   capture the returned revision number. Resolve only after the publish and any
   requested implementation work have succeeded.
6. Generate the server's deterministic source-to-result candidates for that
   exact published revision:

   ```sh
   draft feedback changes <review-id> \
     --result-version <published-version> --json > <changes-file>.json
   ```

   The output includes both content hashes, every submitted comment, and every
   detected change with its zero-based document-order `ordinal` and
   before/result anchors. Re-running this command for the same immutable
   versions is safe and produces the same candidate IDs. Repeated equal edits
   remain separate candidates; never deduplicate them by quote text.
7. Create a provenance manifest JSON object with this exact shape:

   ```json
   {
     "schema_version": 1,
     "result_version": 8,
     "source_content_hash": "sha256:...",
     "result_content_hash": "sha256:...",
     "comments": [
       {
         "comment_id": "...",
         "outcome": "addressed",
         "message": "Added a measurable health gate."
       }
     ],
     "changes": [
       {
         "candidate_id": "chg_...",
         "classification": "review_comment",
         "summary": "Made the health gate measurable.",
         "comment_ids": ["..."]
       }
     ]
   }
   ```

   Account for every comment exactly once with `addressed`,
   `partially_addressed`, `declined`, `needs_user`, or `no_document_change`.
   Account for every candidate exactly once as `review_comment`,
   `agent_initiated`, or `mechanical`. Comment-linked changes require one or
   more comment IDs from this review; agent-initiated and mechanical changes
   require an empty `comment_ids` array. A comment marked addressed or
   partially addressed must link to at least one change. Declined, needs-user,
   and no-document-change comments must not be linked. Preserve the hashes and
   result version exactly as returned; do not guess candidate IDs or causality.
   Many comments may link to one change and one comment may link to many
   changes.

   If comparison returns `comparison_unavailable`, keep the review pending and
   report the bound that was hit; do not invent a manifest or resolve the batch
   as addressed.
8. Resolve with the complete manifest:

   ```sh
   draft feedback resolve <review-id> \
     --disposition addressed \
     --result-version <published-version> \
     --provenance <manifest-file>.json \
     --message "Applied in version <published-version>" --json
   ```

   Draft recomputes the candidates and validates full coverage in the same
   transaction that resolves the review. If validation fails, the published
   revision survives and the review remains pending; correct the manifest
   rather than publishing another revision.
9. Use `declined` with a concise reason when intentionally not applying the
   batch. Use `needs_user` with the precise open question when progress requires
   another human decision. These dispositions accept neither a result version
   nor a provenance manifest. Do not delete, ignore, or falsely resolve
   feedback.
10. Return the new pinned URL and outcome. If the user starts another review
   after seeing the outcome, repeat the workflow; Draft creates a new batch only
   after the prior one is resolved.

## Publish a pinned HTML revision publicly

Use this mode only when the user explicitly asks to make a Draft document
publicly accessible. It reads the requested pinned revision without changing
Draft. A secret GitHub Gist is unlisted rather than private: anyone with the
resulting URL can access it.

1. Parse the Draft URL into its slug and positive `version` query parameter.
   Require a pinned `.html` revision; do not substitute the latest version.
2. Verify `draft auth status` and `gh auth status`. The GitHub token must have
   the `gist` scope.
3. Set task-specific shell variables and use a stable filename:

   ```sh
   public_slug=<slug>
   public_version=<version>
   public_filename="${public_slug}.html"
   public_description="${public_slug} — Draft version ${public_version}"
   ```

4. If no prior Gist was supplied or established in the conversation, create an
   unlisted Gist. Do not pass `--public`, which would list it publicly:

   ```sh
   public_gist_url="$(
     draft get "$public_slug" --version "$public_version" |
       gh gist create --filename "$public_filename" \
         --desc "$public_description" -
   )"
   public_gist_id="${public_gist_url##*/}"
   ```

5. To replace an established one-file HTML Gist, identify its current HTML
   filename, then update and normalize it to the stable filename in one request:

   ```sh
   public_gist_id=<gist-id>
   public_old_filename="$(
     gh api "gists/$public_gist_id" |
       jq -r '[.files[] | select(.filename | endswith(".html"))] |
         if length == 1 then .[0].filename
         else error("expected exactly one HTML file") end'
   )"

   updated_gist_id="$(
     draft get "$public_slug" --version "$public_version" |
       jq -Rs \
         --arg old_filename "$public_old_filename" \
         --arg filename "$public_filename" \
         --arg description "$public_description" \
         '{description:$description,files:{
           ($old_filename):{filename:$filename,content:.}
         }}' |
       gh api --method PATCH "gists/$public_gist_id" --input - --jq .id
   )"
   ```

   Stop if the Gist has zero or multiple HTML files rather than guessing which
   file to replace. Do not create a second Gist merely because its filename
   contains an older version number.
6. Read the post-mutation `raw_url` and prefix it with HTMLPreview. The returned
   raw URL is revision-specific, so always derive a fresh preview URL after an
   update:

   ```sh
   public_raw_url="$(
     gh api "gists/$public_gist_id" |
       jq -r --arg filename "$public_filename" '.files[$filename].raw_url'
   )"
   printf 'https://htmlpreview.github.io/?%s\n' "$public_raw_url"
   ```

7. Return only the clickable HTMLPreview URL. Do not include the Gist source
   URL, hashes, byte comparisons, content audits, or browser-render checks
   unless the user explicitly asks for them. Successful Gist creation or update
   and extraction of its `raw_url` are sufficient.

## Recover safely

- Resume by listing durable pending work, then reopen the selected batch:

  ```sh
  draft feedback --slug <slug> --json
  draft feedback get <review-id> --json
  ```

- After an ambiguous publish response, inspect the current version with
  `draft list --json`, fetch it, and compare its content with the edited source.
  Reuse a proven matching version; never publish a duplicate merely to recover.
- After an ambiguous resolve response, run `draft feedback get <review-id>
  --json`. If it is already resolved, report that outcome instead of retrying.
- If candidate generation or manifest validation is interrupted after publish,
  rerun `draft feedback changes` against the already-published result version
  and rebuild or correct the manifest. Never publish a duplicate revision to
  obtain new candidate IDs.
- Keep a batch unresolved across crashes, timeouts, failed validation, and
  incomplete implementation. Observation is safe and repeatable; resolution is
  the deliberate acknowledgement.
- Process all pending batches for the current document returned by
  `draft feedback --slug <slug> --json` before waiting for new ones. Process
  other documents only when the user's request includes them.
