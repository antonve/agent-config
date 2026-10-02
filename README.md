# agent-config

Global agent instructions and personal skills shared by every machine I use:
the T3 Code pod in my homelab and my Macs.

Skills and instructions follow `main` live. The installer, `bin/agent-config`,
is pinned by each consumer (the T3 image and my `dotfiles` flake lock), so
fetched content is only ever copied, linked and concatenated — never executed.

## Layout

```text
FORMAT                    layout version; installers refuse versions they don't know
instructions/AGENTS.md    global instructions for every harness
skills/<name>/SKILL.md    skills; <name> must match the SKILL.md frontmatter name
bin/agent-config          POSIX sh installer: sync | validate | status
test/e2e.sh               end-to-end harness (TAP output)
```

## What gets installed

| Harness      | Global instructions                  | Skills                     |
|--------------|--------------------------------------|----------------------------|
| Claude Code  | `~/.claude/CLAUDE.md`                | `~/.claude/skills/<name>`  |
| Codex        | `~/.codex/AGENTS.md`                 | `~/.agents/skills/<name>`  |
| OpenCode     | `~/.config/opencode/AGENTS.md`       | `~/.agents/skills/<name>`  |
| Cursor Agent | `~/.cursor/rules/agent-config.mdc`   | `~/.agents/skills/<name>`  |

Every machine gets every target; files for a harness that isn't installed are
simply never read. Instruction files start with a `Managed by agent-config`
header and are regenerated on every change. Skill links point through
`<state>/current/skills/<name>`, so edits to an existing skill are live without
relinking.

The installer only removes links it owns (targets under `<state>/current/skills/`).
Real directories, claude.ai's `~/.claude/skills/synced/` and links owned by
something else are never touched; a name conflict with one of those is reported
and skipped. Deleting a skill here removes its links on the next sync; a rename
is a delete plus an add.

## Day-to-day

Edit a skill or `instructions/AGENTS.md`, run `bin/agent-config validate .`,
and push to `main`. The T3 pod picks it up within five minutes and the Mac
within fifteen. New agent sessions load the change; running sessions keep what
they loaded at start. To apply it immediately:

```sh
t3-agent-config-sync --once                             # T3 (wraps agent-config sync)
agent-config sync --state ~/.local/state/agent-config   # Mac
agent-config status --state <state>                     # active commit, last error
```

A commit that fails validation (bad `SKILL.md`, reserved name, newer `FORMAT`,
instructions over 32 KiB) never becomes active: the previous commit stays in
place and the error appears in `status.json`. Rolling back is a `git revert`.

## First install on a machine

An instruction file that exists without the managed header is never replaced
silently. Compare it with `instructions/AGENTS.md`, then run one sync with
`--adopt`; the old file is kept as `<file>.pre-agent-config`.

## Testing

```sh
sh test/e2e.sh                                   # installer under /bin/sh
AGENT_CONFIG_SHELL="bash --posix" sh test/e2e.sh # installer under another shell
```

The harness builds throwaway homes, state directories and `file://` remotes in
a temporary directory and never touches your real home.

## Third-party skills

These skills are vendored with their licences and contain no executable payload:

| Skill               | Source                | Commit                                     | Licence    |
|---------------------|-----------------------|--------------------------------------------|------------|
| `discernment-nudge` | `anthropics/skills`   | `0a64e398ec6bb34a494f0c347e8ccae53a862f8e` | Apache-2.0 |
| `frontend-design`   | `anthropics/skills`   | `41bbe19d1a1a7eaab5e7bb9050a417e5c6cffc8f` | Apache-2.0 |
| `better-ui`         | `jakubkrehel/skills`  | `267330e1adfc66a718fb65fa6918c1f06d0a689e` | MIT        |
| `emil-design-eng`   | `emilkowalski/skills` | `d23d7f88a2e21c9e4b1418c7abe420f5c1052ba7` | MIT        |

`frontend-design` carries a local change: it proceeds with stated design
assumptions when missing context is safe to infer, and asks only when a choice
could materially change the result.

## Consumers

- **T3 Code** (`antonve/homelab`, `images/t3-code/`): the entrypoint runs one
  bounded sync before T3 starts and the `agent-config-sync` sidecar repeats it
  every five minutes. The image keeps its own storage-safety block (appended
  with `--append`) and the `t3-expose-development-server` skill (`--reserve`).
- **Mac** (`antonve/dotfiles`): Home Manager activation runs one sync and a
  launchd agent repeats it every fifteen minutes.

Changing `bin/agent-config` takes effect only after bumping the pinned commit
in both consumers. Bump `FORMAT` only for layout changes older installers
can't handle.
