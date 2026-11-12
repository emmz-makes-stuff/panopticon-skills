#!/usr/bin/env bash
# Tests hooks/panopticon-hook.sh (agent-interaction 7.1) with a fake `panopticon` on PATH, and with none.
# Run from anywhere: bash plugins/panopticon/tests/panopticon-hook.test.sh. Prints PASS/FAIL per case; exits 1 on
# any failure.

set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
hook="$here/../hooks/panopticon-hook.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/panopticon-hook-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

# Only the basics on PATH, so a real panopticon never leaks in.
base_path="/usr/bin:/bin"
event='{"hook_event_name":"Stop","session_id":"s1","cwd":"/repo"}'
failures=0

# A fake `panopticon` with the given body, in its own bin folder; prints the folder.
fake() {
  local name=$1 body=$2
  mkdir -p "$work/$name"
  printf '#!/usr/bin/env bash\n%s\n' "$body" >"$work/$name/panopticon"
  chmod +x "$work/$name/panopticon"
  printf '%s' "$work/$name"
}

# check <case> <PATH> <expected stdout>
check() {
  local name=$1 path=$2 expected=$3 out code
  out=$(printf '%s' "$event" | PATH="$path" bash "$hook" 2>"$work/stderr")
  code=$?
  if [ "$code" -eq 0 ] && [ "$out" = "$expected" ] && [ ! -s "$work/stderr" ]; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s: exit %s, stdout [%s], stderr [%s]\n' "$name" "$code" "$out" "$(cat "$work/stderr")"
    failures=$((failures + 1))
  fi
}

check "no panopticon on PATH: exit 0, empty stdout" "$base_path" ""

answers=$(fake answers 'read -r input; [ "$1" = hook ] || exit 9; printf "{\"seen\":%s}\n" "$input"')
check "panopticon answers: its stdout passes through, with the event it read" \
  "$answers:$base_path" "{\"seen\":$event}"

quiet=$(fake quiet 'cat >/dev/null')
check "panopticon prints nothing: exit 0, empty stdout" "$quiet:$base_path" ""

fails=$(fake fails 'cat >/dev/null; echo "{\"partial\":true}"; echo "boom" >&2; exit 3')
check "panopticon fails: exit 0, empty stdout, nothing on stderr" "$fails:$base_path" ""

if [ "$failures" -gt 0 ]; then
  printf '%s failed\n' "$failures"
  exit 1
fi

printf 'all passed\n'
