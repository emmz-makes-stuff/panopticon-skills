#!/usr/bin/env bash
# PostToolUse hook: when an Edit/MultiEdit/Write touches openspec/changes/<change>/tasks.md,
# tell the agent to call Panopticon's report_progress for that change.
# A hook can't call an MCP tool itself, so this injects context instead of reporting.
# Silent (exit 0, no output) for every other file, and if the input can't be parsed.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  # Fallback without jq: pull the first "file_path":"..." value out of the JSON.
  file_path=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi

[ -n "$file_path" ] || exit 0

# Normalise Windows separators, then match .../openspec/changes/<change>/tasks.md.
file_path=${file_path//\\//}
case "$file_path" in
  */openspec/changes/archive/*) exit 0 ;;  # archives are reported by the bridge's watcher
  */openspec/changes/*/tasks.md | openspec/changes/*/tasks.md) ;;
  *) exit 0 ;;
esac

change=${file_path%/tasks.md}
change=${change##*/}
[ -n "$change" ] || exit 0

# A change name is a folder name; refuse anything that would break the JSON below.
case "$change" in
  *[\"\\]*) exit 0 ;;
esac

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Panopticon: tasks.md for the OpenSpec change '${change}' just changed. Call the panopticon report_progress tool now with change: \"${change}\" and section: the number of the '## N.' section you are working on, so the dashboard stays current. If it fails, say so briefly and carry on; /panopticon:setup diagnoses it."}}
EOF
