#!/usr/bin/env bash
# Conformance runner for the OKF (knowledge) standard.
#
# Diffs a validator's --json output against expected/*.json for every fixture.
# Exits 0 iff all match. The default validator is CB's Elixir `mix okf.validate`
# (via ../bin/okf-validate). ANY implementation of the format must reproduce
# these expected results; point VALIDATE_CMD at it to test:
#
#   VALIDATE_CMD="python3 /path/to/validate.py" ./okf/conformance/run.sh
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXP="$HERE/expected"
VALIDATE_CMD="${VALIDATE_CMD:-$HERE/../bin/okf-validate}"

pass=0
fail=0

while IFS= read -r fixture; do
  name="$(basename "$fixture")"
  expected="$EXP/$name.json"
  if [[ ! -f "$expected" ]]; then
    echo "MISSING EXPECTED: $name"
    fail=$((fail + 1))
    continue
  fi
  # shellcheck disable=SC2086 # VALIDATE_CMD is intentionally word-split into argv
  actual="$($VALIDATE_CMD "$fixture" --json || true)"
  if diff -u "$expected" <(printf '%s\n' "$actual") >/dev/null 2>&1; then
    echo "ok   $name"
    pass=$((pass + 1))
  else
    echo "FAIL $name"
    diff -u "$expected" <(printf '%s\n' "$actual") || true
    fail=$((fail + 1))
  fi
done < <(find "$HERE/fixtures" -mindepth 2 -maxdepth 2 -type d | sort)

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
