---
name: report-progress
description: Keep the Panopticon dashboard current while building an OpenSpec change — call the panopticon report_progress tool when starting or resuming a change, after ticking tasks in tasks.md, and when a section lands, then read its reply. Use whenever you work through an OpenSpec change (/opsx:apply or any section-by-section build loop) in a repo with the panopticon MCP server, when a hook says tasks.md changed, or when the user says "report progress", "update the dashboard" or "tell Panopticon". Also use it whenever you need the user to look at or act on a web page (review a pull request, approve a run, check how a page looks): call request_visit and wait for its answer.
---

# Report progress to Panopticon

Panopticon is a live dashboard of agents working through OpenSpec changes. The `panopticon` MCP server
(registered by this plugin, running `panopticon mcp` locally) offers `report_progress`, `list_projects`,
`tag_change` and `request_visit`. This skill is mostly about `report_progress`. Each call sends the change's whole
folder (`proposal.md`, `design.md`, `tasks.md`, specs, devlog) from the working copy, and the server recomputes the
card from `tasks.md`. For `request_visit`, see [Visit requests](#visit-requests).

## The tool

- `change` (required): the folder name under `openspec/changes/`, e.g. `team-auth`. Never a path.
- `section` (optional): the number of the `## N.` section in `tasks.md` you're working on, e.g. `2`.

You only name the change. The bridge works out the repo (from `origin`), the documents, the agent and the
machine itself.

The plugin's session hooks already tell the dashboard what you're doing from moment to moment, and when you're
waiting on a question. That costs you nothing, and it doesn't replace reporting: only `report_progress` updates
the change's tasks and documents.

The reply states progress, e.g. `Overall 7/20 · section 2 Core 2/5`. Check it against what you think you've
ticked: a mismatch usually means `tasks.md` wasn't saved, or a task line isn't a `- [x]` checkbox.

## When to report

1. **Starting or resuming a change**: once, with the section you're about to work on.
2. **After ticking tasks in `tasks.md`**: this plugin's hook reminds you after every edit to a change's
   `tasks.md`. Do it then, with the current section.
3. **When a section lands**: after its commit, with that section, so the card shows it complete.
4. **When you move to the next section**: with the new section number.

You don't need to report:

- **Archives.** When `/opsx:archive` moves the folder to `openspec/changes/archive/`, the running bridge notices
  and reports the archive itself.
- **Edits to other documents alone.** They go up with the next report anyway. Report sooner only if the user
  asks, or a big design change should show now.

Reporting is a side channel. Don't let it block the work: if a call fails, tell the user in one line what the
error said, then carry on building. Don't retry in a loop.

## When it fails

The error text says what's wrong. The usual ones:

| Error says | Meaning | Fix |
| --- | --- | --- |
| No git repository was found | The bridge started outside the repo | Restart Claude Code from inside the repo |
| no 'origin' remote | The repo identity comes from `origin` | Add a remote |
| No change '…' was found | The name doesn't match a folder | Use the exact folder name under `openspec/changes/` |
| isn't configured / rejected the … token | No login, or the token was revoked | The user runs `! panopticon login --server <url>` |
| Couldn't reach the Panopticon server | The server is down, or the URL is wrong | Check `PANOPTICON_SERVER_URL` and the server |
| … bytes; the limit is … | A file or the folder is too big | Move large files out of the change's folder |

If the `report_progress` tool isn't available at all, or the cause isn't clear, suggest `/panopticon:setup`.
Never try to log in, or to read or print the saved token, yourself.

## Visit requests

When you need the user to look at or act on a web page, such as reviewing a pull request, approving a pipeline run
or checking how a page looks, call `request_visit` instead of only writing the link in your reply.

- `url` (required): an absolute `http` or `https` URL, with no user name or password in it.
- `reason` (required): why, in a sentence, e.g. "Review the PR for the tags change".
- `action` (optional): what to do there, e.g. "Approve it if the checks are green".

If the user is away, the call waits until they answer on the dashboard, and returns Done or Can't, their note, and
who answered. Wait for that answer before you rely on the visit. Otherwise it returns at once and says to ask in the
terminal: do that, with the URL in your question.
