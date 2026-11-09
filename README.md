# panopticon-skills

A Claude Code plugin marketplace for [Panopticon](https://github.com/emmz-makes-stuff/apanopticon): a live dashboard
of coding agents working through [OpenSpec](https://github.com/Fission-AI/OpenSpec) changes.

## Install

```text
/plugin marketplace add emmz-makes-stuff/panopticon-skills
/plugin install panopticon@panopticon-skills
```

Then restart Claude Code and run `/panopticon:setup`.

The plugin needs the `panopticon` CLI on your `PATH`, logged in to your server:

```sh
panopticon login --server https://panopticon.example.com
```

Until releases are published, build the CLI from the Panopticon repo with `make install`. See its
[`docs/cli.md`](https://github.com/emmz-makes-stuff/apanopticon/blob/main/docs/cli.md).

## The `panopticon` plugin

| Part | What it does |
| --- | --- |
| MCP server | Registers `panopticon mcp`, the local bridge offering `report_progress`. Repos no longer need their own `.mcp.json` entry. |
| `report-progress` skill | Tells the agent when to report (starting a change, after ticking tasks, when a section lands), and what the reply and errors mean. |
| `tasks.md` hook | After any Edit or Write to `openspec/changes/<change>/tasks.md`, reminds the agent to call `report_progress` for that change. A hook can't call an MCP tool itself, so this is a nudge. |
| `/panopticon:setup` | Checks the CLI, the login, the repo's `origin` and `openspec/changes`, the MCP server, and a duplicate `.mcp.json` entry. |

It works with plain OpenSpec (`/opsx:apply`), and it fits alongside a section-by-section build loop such as
[emmz](https://github.com/emmz-makes-stuff/emmz-dev-skills).

Archives need nothing extra: the running bridge notices when `/opsx:archive` moves a change, and reports it.

### Overriding the server for one repo

The plugin's server uses the saved login. To point one repo somewhere else, give it its own `.mcp.json` entry
with an `env` block, as in `docs/cli.md`, and disable this plugin in that repo, so there aren't two bridges.

## License

MIT
