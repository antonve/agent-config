#!/bin/sh
# End-to-end harness for bin/agent-config.
#
# Every case builds a throwaway home, state directory and local file:// remote
# under one temporary directory; the caller's real home is never touched.
# Output is TAP, so `sh test/e2e.sh | tee e2e.log` is the inspectable artifact.
set -u

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
bin="$root/bin/agent-config"
# Set AGENT_CONFIG_SHELL (for example "bash --posix") to run the installer under a specific shell.
agent_config() { ${AGENT_CONFIG_SHELL:-} "$bin" "$@"; }
work=$(mktemp -d "${TMPDIR:-/tmp}/agent-config-e2e.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.invalid
export GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.invalid
export GIT_CONFIG_NOSYSTEM=1
unset AGENT_CONFIG_REMOTE AGENT_CONFIG_BRANCH

home="$work/home"
state="$work/state"
remote="$work/remote.git"
src="$work/src"
log="$work/last.log"
export HOME="$home"

total=0
failures=0
case_failed=0

fail() {
  case_failed=1
  echo "  # $*"
}

run_case() {
  total=$((total + 1))
  case_failed=0
  reset
  "$1"
  if [ "$case_failed" -eq 0 ]; then
    echo "ok $total - $2"
  else
    failures=$((failures + 1))
    echo "not ok $total - $2"
    sed 's/^/  #   /' "$log" 2>/dev/null
  fi
}

reset() {
  rm -rf "$home" "$state" "$remote" "$src" "$log"
  mkdir -p "$home"
  git init -q --bare -b main "$remote"
  git init -q -b main "$src"
  git -C "$src" remote add origin "$remote"
  printf '1\n' >"$src/FORMAT"
  mkdir -p "$src/instructions"
  printf '# Shared\n\nShared rule one.\n' >"$src/instructions/AGENTS.md"
  skill alpha
  skill beta
  commit base
}

skill() { # skill DIR [FRONTMATTER-NAME]
  mkdir -p "$src/skills/$1"
  printf -- '---\nname: %s\ndescription: Test skill %s.\n---\n\nBody of %s.\n' \
    "${2:-$1}" "$1" "$1" >"$src/skills/$1/SKILL.md"
}

commit() {
  git -C "$src" add -A
  git -C "$src" commit -q -m "$1"
  git -C "$src" push -q origin HEAD:main
}

head_sha() { git -C "$src" rev-parse HEAD; }

sync() {
  agent_config sync --once --state "$state" --remote "file://$remote" "$@" >"$log" 2>&1
}

active_sha() {
  target=$(readlink "$state/current" 2>/dev/null) || return 1
  basename "$target"
}

quiet() { "$@" >"$log" 2>&1; }
expect_ok() { "$@" || fail "expected success: $*"; }
expect_fail() { if "$@"; then fail "expected failure: $*"; fi; }
expect_active() { [ "$(active_sha)" = "$1" ] || fail "active commit is '$(active_sha)', expected '$1'"; }
expect_link() { # expect_link PATH TARGET
  [ -L "$1" ] || { fail "missing link $1"; return; }
  [ "$(readlink "$1")" = "$2" ] || fail "$1 points to $(readlink "$1"), expected $2"
}
expect_absent() { if [ -e "$1" ] || [ -L "$1" ]; then fail "unexpected $1"; fi; }
expect_contains() { grep -q -F -- "$2" "$1" 2>/dev/null || fail "$1 does not contain '$2'"; }
expect_lacks() { if grep -q -F -- "$2" "$1" 2>/dev/null; then fail "$1 unexpectedly contains '$2'"; fi; }
expect_status() { agent_config status --state "$state" 2>/dev/null | grep -q -F -- "$1" || fail "status lacks '$1'"; }

instruction_files="$home/.claude/CLAUDE.md $home/.codex/AGENTS.md $home/.config/opencode/AGENTS.md $home/.cursor/rules/agent-config.mdc"
skill_dirs="$home/.claude/skills $home/.agents/skills"

case_fresh_install() {
  expect_ok sync
  sha=$(head_sha)
  expect_active "$sha"
  for dir in $skill_dirs; do
    expect_link "$dir/alpha" "$state/current/skills/alpha"
    expect_link "$dir/beta" "$state/current/skills/beta"
    expect_contains "$dir/alpha/SKILL.md" "Body of alpha."
  done
  for file in $instruction_files; do
    expect_contains "$file" "Shared rule one."
    expect_contains "$file" "Managed by agent-config"
    expect_contains "$file" "$sha"
  done
  [ "$(head -n 1 "$home/.cursor/rules/agent-config.mdc")" = "---" ] || fail "Cursor rule lacks frontmatter"
  expect_contains "$home/.cursor/rules/agent-config.mdc" "alwaysApply: true"
  expect_status "$sha"
}

case_idempotent() {
  expect_ok sync
  sleep 1
  touch "$work/marker"
  sleep 1
  expect_ok sync
  changed=$(find "$home" "$state/current" -newer "$work/marker")
  [ -z "$changed" ] || fail "second run changed: $changed"
}

case_delete_rename_edit() {
  expect_ok sync
  git -C "$src" rm -q -r skills/alpha
  git -C "$src" mv skills/beta skills/gamma
  skill gamma
  commit "delete alpha, rename beta to gamma"
  expect_ok sync
  for dir in $skill_dirs; do
    expect_absent "$dir/alpha"
    expect_absent "$dir/beta"
    expect_link "$dir/gamma" "$state/current/skills/gamma"
  done
  sleep 1
  touch "$work/marker"
  sleep 1
  printf 'Edited gamma.\n' >>"$src/skills/gamma/SKILL.md"
  commit "edit gamma"
  expect_ok sync
  expect_active "$(head_sha)"
  for dir in $skill_dirs; do
    expect_contains "$dir/gamma/SKILL.md" "Edited gamma."
    [ -z "$(find "$dir/gamma" -prune -newer "$work/marker")" ] || fail "$dir/gamma was relinked for a content edit"
  done
}

case_foreign_preserved() {
  mkdir -p "$home/.claude/skills/synced/remote" "$home/.claude/skills/realdir" "$home/.agents/skills"
  printf 'real\n' >"$home/.claude/skills/realdir/SKILL.md"
  ln -s /nonexistent/image-skill "$home/.agents/skills/image-skill"
  ln -s /opt/elsewhere/beta "$home/.agents/skills/beta"
  expect_fail sync
  expect_contains "$log" "$home/.agents/skills/beta"
  expect_link "$home/.claude/skills/alpha" "$state/current/skills/alpha"
  expect_link "$home/.claude/skills/beta" "$state/current/skills/beta"
  git -C "$src" rm -q -r skills/alpha
  commit "delete alpha"
  expect_fail sync
  expect_absent "$home/.claude/skills/alpha"
  [ -d "$home/.claude/skills/synced/remote" ] || fail "synced/ was removed"
  expect_contains "$home/.claude/skills/realdir/SKILL.md" "real"
  expect_link "$home/.agents/skills/image-skill" /nonexistent/image-skill
  expect_link "$home/.agents/skills/beta" /opt/elsewhere/beta
}

case_reserved_collision() {
  expect_ok sync
  good=$(head_sha)
  skill reserved-one
  commit "add reserved"
  expect_fail sync --reserve reserved-one
  expect_active "$good"
  expect_contains "$log" "reserved"
  expect_status "reserved"
  expect_absent "$home/.claude/skills/reserved-one"
}

case_malformed_skill() {
  expect_ok sync
  good=$(head_sha)
  mkdir -p "$src/skills/broken"
  printf 'no skill file\n' >"$src/skills/broken/README.md"
  commit "skill without SKILL.md"
  expect_fail sync
  expect_active "$good"
  expect_fail quiet agent_config validate "$src"
  skill broken mismatch
  commit "skill with mismatched name"
  expect_fail sync
  expect_active "$good"
  expect_absent "$home/.claude/skills/broken"
  skill broken
  commit "fix skill"
  expect_ok quiet agent_config validate "$src"
  expect_ok sync
  expect_active "$(head_sha)"
}

case_newer_format() {
  expect_ok sync
  good=$(head_sha)
  printf '2\n' >"$src/FORMAT"
  commit "format 2"
  expect_fail sync
  expect_active "$good"
  expect_status "FORMAT"
}

case_unreachable_remote() {
  expect_ok sync
  good=$(head_sha)
  started=$(date +%s)
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=protocol.ext.allow GIT_CONFIG_VALUE_0=always \
    agent_config sync --once --state "$state" --remote 'ext::sh -c "sleep 30"' --timeout 3 >"$log" 2>&1 &&
    fail "hanging fetch reported success"
  elapsed=$(($(date +%s) - started))
  [ "$elapsed" -le 10 ] || fail "hanging fetch took ${elapsed}s"
  expect_active "$good"
  for file in $instruction_files; do expect_contains "$file" "Shared rule one."; done
  expect_status "fetch"
}

case_no_checkout_offline() {
  printf '<!-- BEGIN APPENDED -->\nAppended guard.\n<!-- END APPENDED -->\n' >"$work/append.md"
  expect_fail quiet agent_config sync --once --state "$state" --remote "file://$work/missing.git" --append "$work/append.md"
  for file in $instruction_files; do
    expect_contains "$file" "Appended guard."
    expect_lacks "$file" "Shared rule one."
  done
  expect_absent "$home/.claude/skills/alpha"
  rm -rf "$home" "$state"
  mkdir -p "$home"
  expect_fail quiet agent_config sync --once --state "$state" --remote "file://$work/missing.git"
  for file in $instruction_files; do expect_absent "$file"; done
}

case_hand_edited_target() {
  mkdir -p "$home/.codex"
  printf 'my notes\n' >"$home/.codex/AGENTS.md"
  expect_fail sync
  [ "$(cat "$home/.codex/AGENTS.md")" = "my notes" ] || fail "hand-edited file was overwritten"
  expect_contains "$home/.claude/CLAUDE.md" "Shared rule one."
  expect_ok sync --adopt
  expect_contains "$home/.codex/AGENTS.md" "Shared rule one."
  expect_contains "$home/.codex/AGENTS.md.pre-agent-config" "my notes"
}

case_lock() {
  mkdir -p "$state/lock"
  started=$(date +%s)
  expect_fail sync --timeout 2
  [ $(($(date +%s) - started)) -le 8 ] || fail "lock wait was not bounded"
  expect_contains "$log" "lock"
  touch -t 200001010000 "$state/lock"
  expect_ok sync --timeout 2
  agent_config sync --once --state "$state" --remote "file://$remote" >"$work/a.log" 2>&1 &
  first=$!
  agent_config sync --once --state "$state" --remote "file://$remote" >"$work/b.log" 2>&1 &
  second=$!
  wait "$first" || fail "first concurrent sync failed: $(cat "$work/a.log")"
  wait "$second" || fail "second concurrent sync failed: $(cat "$work/b.log")"
  expect_absent "$state/lock"
  [ -z "$(find "$state" -name '.tmp*')" ] || fail "temporary files left behind"
  expect_active "$(head_sha)"
}

case_prune() {
  for i in 1 2 3 4 5; do
    printf 'Revision %s.\n' "$i" >>"$src/instructions/AGENTS.md"
    commit "revision $i"
    expect_ok sync
  done
  count=$(find "$state/checkouts" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
  [ "$count" -eq 3 ] || fail "kept $count checkouts, expected 3"
  [ -d "$state/checkouts/$(head_sha)" ] || fail "active checkout was pruned"
}

case_oversized_instructions() {
  expect_ok sync
  good=$(head_sha)
  awk 'BEGIN { for (i = 0; i < 700; i++) print "Padding line that makes the instructions too large." }' \
    >>"$src/instructions/AGENTS.md"
  commit "oversized"
  expect_fail sync
  expect_active "$good"
  expect_status "KiB"
}

echo "TAP version 13"
echo "# agent-config $(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown) on $(uname -s) with $(readlink /bin/sh 2>/dev/null || echo sh)"
run_case case_fresh_install "fresh home gets every link and generated file for all four harnesses"
run_case case_idempotent "a second run with no changes changes nothing on disk"
run_case case_delete_rename_edit "deleted and renamed skills are unlinked; edits need no relink"
run_case case_foreign_preserved "foreign links and directories are preserved and conflicts reported"
run_case case_reserved_collision "a reserved-name collision keeps the previous commit"
run_case case_malformed_skill "a missing or mismatched SKILL.md keeps the previous commit"
run_case case_newer_format "a newer FORMAT is refused"
run_case case_unreachable_remote "a hanging remote is bounded and keeps the previous commit"
run_case case_no_checkout_offline "with no checkout and no remote only the appended block is written"
run_case case_hand_edited_target "a hand-edited target is refused until --adopt, which keeps a backup"
run_case case_lock "the lock waits boundedly, steals stale locks and serializes syncs"
run_case case_prune "pruning keeps three checkouts including the active one"
run_case case_oversized_instructions "oversized instructions are refused"
echo "1..$total"
echo "# $((total - failures)) passed, $failures failed"
[ "$failures" -eq 0 ]
