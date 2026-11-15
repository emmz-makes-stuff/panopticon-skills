# panopticon-skills

A Claude Code plugin marketplace for [Panopticon](https://github.com/emmz-makes-stuff/panopticon): a live dashboard
of coding agents working through [OpenSpec](https://github.com/Fission-AI/OpenSpec) changes.

## Install

```text
/plugin marketplace add emmz-makes-stuff/panopticon-skills
/plugin install panopticon@panopticon-skills
```

Then restart Claude Code and run `/panopticon:setup`.

It needs **Claude Code 2.1.322 or later**: that's the version the session hooks were tested on.

The plugin needs the `panopticon` CLI on your `PATH`, logged in to your server:

```sh
panopticon login --server https://panopticon.example.com
```

Until releases are published, build the CLI from the Panopticon repo with `make install`. See its
[`docs/cli.md`](https://github.com/emmz-makes-stuff/panopticon/blob/main/docs/cli.md).

## The `panopticon` plugin

| Part | What it does |
| --- | --- |
| MCP server | Registers `panopticon mcp`, the local bridge offering `report_progress`, `list_projects`, `tag_change` and `request_visit`. Repos no longer need their own `.mcp.json` entry. |
| `report-progress` skill | Tells the agent when to report (starting a change, after ticking tasks, when a section lands), and what the reply and errors mean. |
| `tasks.md` hook | After any Edit or Write to `openspec/changes/<change>/tasks.md`, reminds the agent to call `report_progress` for that change. A hook can't call an MCP tool itself, so this is a nudge. |
| Session hooks | Tell the dashboard what each session is doing, and what it waits on, without the agent spending a token: `PreToolUse`, `PostToolUse`, `Stop`, `UserPromptSubmit` and `SessionEnd` (async), plus `AskUserQuestion`, `request_visit` and `PermissionRequest` (sync, for away mode). All run `hooks/panopticon-hook.sh`, which runs `panopticon hook`. |
| `/panopticon:setup` | Checks the CLI, the login, the repo's `origin` and `openspec/changes`, the MCP server, a duplicate `.mcp.json` entry, and your away switch. |

It works with plain OpenSpec (`/opsx:apply`), and it fits alongside a section-by-section build loop such as
[emmz](https://github.com/emmz-makes-stuff/emmz-dev-skills).

Archives need nothing extra: the running bridge notices when `/opsx:archive` moves a change, and reports it.

### Sessions on the dashboard

Each card lists the sessions working on its change: what each is doing ("Run make gates"), or what it waits on
(a question, a permission prompt, or you, after its turn), and for how long. The session hooks send this: the
session's state, a one-line activity, and an asked question's text and options, which only you and the Project's
owners see. A permission prompt's command stays on the machine unless you're away (below).

The hooks never get in the session's way. If `panopticon` isn't on `PATH`, or it fails, the wrapper exits 0 with no
output, and Claude Code carries on as if there were no hook. `panopticon hook` logs its failures to `hook.log`, next
to the saved login.

### Away mode: answer prompts from the dashboard

Turn away mode on when you step away from the terminal:

```sh
panopticon away on     # or the Away switch in the dashboard's header
panopticon away        # Away since 2026-11-11 14:02: your sessions' questions and permission prompts wait for an answer on the dashboard.
panopticon away off    # Not away: your sessions' prompts are answered in the terminal.
```

While you're away, a question (`AskUserQuestion`) or a permission prompt from any of your sessions is **held for the
dashboard**:

- **In the terminal**, the session pauses on the hook. Nothing is asked there, and the card says it needs you.
- **On the dashboard**, the card shows "Needs you" with the question's form, or the tool and its input with
  Allow once and Deny. You, and the owners of the change's Project, can answer. Everyone else sees only
  "Needs <you>: question".
- **Answered**, the session carries on with the answer, and is told who gave it ("Answered by Bob via Panopticon").
  Allow runs the tool once; it never adds a permission rule. The change page lists every answer given this way.
- **Not answered**, the terminal takes the prompt back: when you turn away off, after 8 hours, or if the server
  can't be reached for a minute. Then it asks as usual.

Whether a prompt is held is decided when it's asked. Turning away on doesn't take over a prompt already waiting in
the terminal, so turn it on before you leave.

### Visit requests: "please open this page"

Sometimes the agent needs you in a browser: to review a pull request, approve a pipeline run, or check how a page
looks. No hook can tell that by itself, so the agent asks with the bridge's `request_visit` tool, giving the URL, a
reason, and optionally what to do there. The `report-progress` skill and the tool's own description tell it when.

- **While you're away**, the request is held like a question. The card shows the reason, the action, and the URL
  in full as a link that opens in a new tab. Answer **Done** or **Can't**, with an optional note, and the agent is
  told your answer and who gave it. The change page records who answered, the URL and the outcome, but not the note.
  Only you and the Project's owners see the URL. Everyone else sees "Needs <you>: visit a page".
- **Otherwise** (you're at the terminal, or the request is released, as any prompt is), the tool returns at once,
  and the agent asks you in the terminal with the URL in the question.
- Only `http` and `https` URLs are accepted, with no user name or password in them.

Visit requests need plugin 0.3.0 and a `panopticon` CLI that has `request_visit`: update both together
(`panopticon update`, then update the plugin). With an older plugin, a visit request can show on the card for about
a minute and a half after the agent has already been told to ask in the terminal.

### Overriding the server for one repo

The plugin's server uses the saved login. To point one repo somewhere else, give it its own `.mcp.json` entry
with an `env` block, as in `docs/cli.md`, and disable this plugin in that repo, so there aren't two bridges.

## License

MIT
