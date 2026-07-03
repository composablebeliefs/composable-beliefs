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
  $SUDO apt-get update -qq
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
