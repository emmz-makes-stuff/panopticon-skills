#!/usr/bin/env bash
# Every Panopticon session hook (agent-interaction D1): passes the hook event on stdin to `panopticon hook`, which
# tells the dashboard what the session is doing and, for a question or permission prompt held while away, waits for
# the answer from the dashboard and prints it for Claude Code.
#
# A hook must never get in the session's way, so this always exits 0:
# - with no `panopticon` on PATH, it does nothing and prints nothing;
# - if `panopticon hook` fails, nothing it printed is passed on, so Claude Code does what it would with no hook.
# Only a successful run's stdout reaches Claude Code. `panopticon hook` logs its own failures to its hook log.

if ! command -v panopticon >/dev/null 2>&1; then
  cat >/dev/null
  exit 0
fi

if output=$(panopticon hook 2>/dev/null) && [ -n "$output" ]; then
  printf '%s\n' "$output"
fi

exit 0
