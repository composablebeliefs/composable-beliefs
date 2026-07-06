#!/bin/bash
# SessionStart hook: provision the Elixir toolchain for Claude Code on the web.
#
# Remote containers ship without Erlang/Elixir, and the outbound proxy blocks
# GitHub release downloads outside the session's repo scope - so Erlang comes
# from apt and Elixir from the official builds.hex.pm mirror (which the proxy
# allows, same host mix fetches deps from). Local sessions are untouched.
#
# Idempotent: every step checks before acting, and the container state is
# cached after the hook completes, so warm starts fall straight through.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Refresh git refs (ENVIRONMENT_DEFECTS.md defect 2). The container image is
# pre-baked and cached across sessions, so the local default-branch ref is
# frozen at image-build time and can lag origin by many commits (git never
# advances a local branch on its own; fetch only moves remote-tracking refs).
# A routine `git checkout -B <branch> main` would then silently base work on
# stale history. Fetch, then fast-forward the local default branch to match
# origin - `merge --ff-only` when it is the checked-out branch, `update-ref`
# after an ancestor check otherwise. Only ever fast-forwards; never rewrites
# history (cb:b573/cb:b585). Runs before provisioning so a provisioning
# failure (defect 3) cannot block it; failures are non-fatal (offline / no
# remote).
repo_git() { git -C "${CLAUDE_PROJECT_DIR:-.}" "$@"; }
if repo_git remote get-url origin >/dev/null 2>&1; then
  repo_git fetch --quiet origin || true
  default_ref="$(repo_git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
  default_branch="${default_ref#origin/}"
  if repo_git rev-parse --verify --quiet "refs/heads/$default_branch" >/dev/null &&
    repo_git rev-parse --verify --quiet "refs/remotes/origin/$default_branch" >/dev/null; then
    if [ "$(repo_git branch --show-current 2>/dev/null)" = "$default_branch" ]; then
      repo_git merge --ff-only "origin/$default_branch" >/dev/null 2>&1 &&
        echo "fast-forwarded checked-out $default_branch to origin/$default_branch" || true
    elif repo_git merge-base --is-ancestor "$default_branch" "origin/$default_branch" 2>/dev/null; then
      repo_git update-ref "refs/heads/$default_branch" "origin/$default_branch"
      echo "fast-forwarded local $default_branch to origin/$default_branch"
    fi
  fi
fi

ELIXIR_VSN="1.16.3"
OTP_MAJOR="25"
ELIXIR_DIR="/opt/elixir"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo -n"
fi

# Erlang/OTP from apt (erlang-nox = full headless OTP; matches OTP_MAJOR on
# ubuntu 24.04). apt's own elixir is too old for mix.exs (~> 1.16), hence the
# separate precompiled Elixir below.
if ! command -v erl >/dev/null 2>&1; then
  # --allow-releaseinfo-change: a baked-in PPA renaming its InRelease Label
  # (ENVIRONMENT_DEFECTS.md defect 3) must not block toolchain provisioning.
  $SUDO apt-get update -qq --allow-releaseinfo-change
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq erlang-nox erlang-dev unzip >/dev/null
fi

# Precompiled Elixir from builds.hex.pm, keyed to the installed OTP major.
if ! "$ELIXIR_DIR/bin/elixir" --version 2>/dev/null | grep -q "Elixir $ELIXIR_VSN"; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/elixir.zip" \
    "https://builds.hex.pm/builds/elixir/v${ELIXIR_VSN}-otp-${OTP_MAJOR}.zip"
  $SUDO mkdir -p "$ELIXIR_DIR"
  $SUDO unzip -oq "$tmp/elixir.zip" -d "$ELIXIR_DIR"
fi

# Make the toolchain visible to the session's shells. The Erlang VM needs a
# UTF-8 locale or Elixir warns and can misbehave on non-ascii graph content.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  grep -qs "$ELIXIR_DIR/bin" "$CLAUDE_ENV_FILE" || {
    echo "export PATH=\"$ELIXIR_DIR/bin:\$PATH\"" >>"$CLAUDE_ENV_FILE"
    echo 'export LC_ALL=C.UTF-8' >>"$CLAUDE_ENV_FILE"
  }
fi
export PATH="$ELIXIR_DIR/bin:$PATH" LC_ALL=C.UTF-8

cd "$CLAUDE_PROJECT_DIR"
mix local.hex --force >/dev/null
mix deps.get
mix compile

echo "elixir toolchain ready: $(elixir --version | tail -1)"
