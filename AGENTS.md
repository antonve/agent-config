# Working on agent-config

This repository is public and is installed onto every machine the owner uses.
`instructions/AGENTS.md` is the owner's global agent instructions; this file
only covers working on the repository itself.

- Never commit credentials, tokens, private keys or private hostnames that are
  not already public. Everything here is published and fetched anonymously.
- Run `bin/agent-config validate .` before pushing. When changing
  `bin/agent-config` or `test/e2e.sh`, also run `sh test/e2e.sh` and
  `AGENT_CONFIG_SHELL="bash --posix" sh test/e2e.sh`.
- Keep `bin/agent-config` POSIX `sh` that works with GNU, BusyBox and macOS
  utilities, and never make it execute content from the fetched tree.
- Installer changes reach machines only after the pinned commit is bumped in
  `antonve/homelab` (`images/t3-code/Dockerfile`) and `antonve/dotfiles`
  (`flake.lock`). Keep `FORMAT` compatible unless a layout change forces a bump.
- A skill directory name must equal its `SKILL.md` frontmatter `name`. Keep
  third-party licence files with the skills they cover.
