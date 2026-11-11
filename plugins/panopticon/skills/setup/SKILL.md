---
name: setup
description: Check that this machine and repo can report to Panopticon — the panopticon CLI is installed, the machine is logged in, the repo has an origin remote and an openspec/changes folder, the report_progress tool is connected, there's no duplicate panopticon server in the repo's .mcp.json, the session hooks can run, and the user knows whether they're away — then fix what's missing or hand the user the command to run. Use when the user runs /panopticon:setup, says "set up panopticon", "is panopticon working?", or when report_progress is missing or failing for an unclear reason.
---

# Set up Panopticon reporting

Run each check in order, and report the results as a checklist: ✅ passed, ❌ failed (with the fix), ⚠️ worth
knowing. Don't stop at the first failure, unless a later check depends on it.

**Never** run `panopticon login` yourself, and never print, `cat` or echo the saved config file or a token. The
login needs the user to approve a code in the dashboard, so hand it over as `! panopticon login --server <url>`.

## 1. The CLI

```sh
command -v panopticon && panopticon --help
```

- Missing: the CLI isn't on `PATH`. Until releases are published, it's built from the Panopticon repo
  (`emmz-makes-stuff/panopticon`) with `make install`, which copies it to `~/.local/bin/panopticon`. If
  `~/.local/bin/panopticon` exists but isn't found, `~/.local/bin` isn't on `PATH`. Offer to help, but ask
  before running anything in another repo.
- Present: `--help` prints the saved login's path on its last line (`Saved login: …`). Keep it for step 2.

## 2. The login

Check the saved login exists and has both values, without showing them:

```sh
jq -e '(.serverUrl | type == "string" and length > 0) and (.token | type == "string" and length > 0)' "<saved login path>" >/dev/null && jq -r '.serverUrl' "<saved login path>"
```

Printing `serverUrl` is fine. Never print `token`.

- No file, or no token: hand over `! panopticon login --server <url>`. Ask the user which server, unless
  `PANOPTICON_SERVER_URL` is set.
- If `PANOPTICON_SERVER_URL` or `PANOPTICON_TOKEN` is set in the environment, say so (⚠️). They override the saved
  login, and a `PANOPTICON_SERVER_URL` naming another server stops the saved token being sent.

## 3. The repo

```sh
git rev-parse --show-toplevel && git remote get-url origin && ls -d "$(git rev-parse --show-toplevel)/openspec/changes"
```

- Not a git repo, or no `origin`: the bridge can't identify the repo. Every report fails until there's a remote.
- No `openspec/changes`: this isn't an OpenSpec repo yet (`openspec init`). Nothing to report.
- Print the `origin` URL with any credentials removed (anything between `//` and `@`).

## 4. The MCP server

This plugin registers the `panopticon` server, which runs `panopticon mcp`. Check that a `report_progress` tool
from it is in your tool list.

- Missing: the CLI wasn't on `PATH` when Claude Code started (step 1), or the server failed to start. The user
  can check with `/mcp`. After fixing, Claude Code has to restart to pick the server up.
- Look at the repo's own `.mcp.json`. If it also defines a `panopticon` server, there are two bridges and two tools
  (⚠️). Suggest removing the repo's entry, unless it sets a deliberate `env` block, e.g. for a different server.
  Ask before editing it.

Don't call `report_progress` to test the connection unless the user agrees: a report shows up on the dashboard.
If they agree, report the change they name, and show the reply.

## 5. The hooks

- **The `tasks.md` hook** reminds the agent to report after each edit to a change's `tasks.md`. It uses `jq` when
  present, and falls back to `sed` without it. If `command -v jq` finds nothing, mention it (⚠️), but it isn't a
  failure.
- **The session hooks** show what this session is doing on the dashboard, and hold prompts while the user is away.
  They need Claude Code 2.1.322 or later: check with `claude --version`, and say so (❌) if it's older. They run
  `panopticon hook`, so they need step 1's CLI; without it they do nothing, silently.
- If the user says the dashboard doesn't show their sessions, look at `hook.log` in the same folder as the saved
  login (step 1's path). It lists `panopticon hook`'s failures, without tokens. Show its last few lines.

## 6. Away mode

```sh
panopticon away
```

It prints whether the user is away (✅ either way, it's information). Explain in one or two lines:

- **Away:** questions and permission prompts from their sessions wait for an answer on the dashboard, and the
  terminal asks nothing. `panopticon away off`, or the Away switch in the dashboard's header, gives them back.
- **Not away:** prompts are answered in the terminal as usual. Turn it on with `panopticon away on` before stepping
  away; a prompt already waiting in the terminal isn't taken over.

Don't change the switch yourself unless the user asks.

## Finish

End with one line: ready to report, or the first thing to fix.
