# Ralph Starter for GitHub Copilot CLI

A minimal [Ralph-loop](https://blog.codacy.com/what-everyone-gets-wrong-about-the-ralph-loop)
driver built on `copilot -p`. Tasks always come from a **GitHub issue**
checklist. The run starts with an interactive planning pass, then each
iteration is a fresh Copilot CLI process that picks the next unchecked task
from the issue, implements it, runs the relevant checks, marks the task
`[x]` on the issue, and commits.

State lives in **git** and the **GitHub issue**, never in the agent's context.

## Prerequisites

- [GitHub Copilot CLI](https://github.com/github/copilot-cli) installed
  (`copilot` on `PATH`).
- An active Copilot subscription and a logged-in session (`copilot /login`).
- The [`gh` CLI](https://cli.github.com/) installed and authenticated
  (`gh auth status`) — tasks are read from and checked off on a GitHub issue.
- This directory initialized as a git repo with a clean working tree.

## Quick start

```bash
cd ralph-starter
git init && git add . && git commit -m "init"

# Create a GitHub issue describing the work (a rough task list is fine —
# the planning step will refine it), then pass its link or number:

./ralph.sh <issue-link-or-number>
```

The run begins with an interactive planning pass where Copilot refines the
issue's task list and may ask you clarifying questions. After you exit that
session, the loop pauses after every iteration so you can review the diff
and Ctrl+C out if things look wrong.

## Environment variables

| var          | default        | meaning                                              |
|--------------|----------------|------------------------------------------------------|
| `ISSUE_LINK` | (1st arg)      | GitHub issue link/number holding the task checklist  |
| `LOG_DIR`    | `logs`         | Per-iteration markdown transcripts (`--share` output)|
| `MODEL`      | (cli default)  | e.g. `claude-sonnet-4.5`, `gpt-5`                    |
| `EFFORT`     | (cli default)  | `none\|low\|medium\|high\|xhigh\|max`                |
| `MAX_ITERS`  | `0`            | Stop after N iterations (0 = unlimited)              |
| `GATE`       | `1`            | If `1`, wait for Enter between iterations            |
| `RALPH_TEST_CMD` | (unset)    | If set, the loop re-runs this command after every iteration and aborts if it fails (e.g. `pytest -q`) |

Examples:

```bash
# Fully autonomous, capped at 10 iterations
GATE=0 MAX_ITERS=10 ./ralph.sh 42

# Use a specific model and higher reasoning effort
MODEL=gpt-5 EFFORT=high ./ralph.sh 42

# Pass the issue via env var instead of an argument
ISSUE_LINK=https://github.com/owner/repo/issues/42 ./ralph.sh

# Enforce green tests after every iteration (recommended)
RALPH_TEST_CMD="pytest -q" ./ralph.sh 42
```

## How it works

0. `ralph.sh` runs an interactive planning pass: Copilot reads the issue,
   asks you any clarifying questions, and writes a clean, ordered `- [ ]`
   checklist back to the issue body.
1. It then reads the issue body and greps for lines starting with `- [ ]`.
2. While any exist, it spawns:

   ```bash
   copilot -p "<ralph prompt>" \
           --allow-all-tools \
           --no-ask-user \
           --share logs/run-<ts>.md \
           -s
   ```

   - `-p` runs Copilot non-interactively in a fresh context.
   - `--allow-all-tools` skips per-tool permission prompts (required for
     non-interactive use).
   - `--no-ask-user` prevents the agent from blocking on clarification
     questions; it must decide and act.
   - `--share` writes a markdown transcript of the run for audit.
   - `-s` strips stats from stdout so it's scripting-friendly.

3. The agent commits its own work (`ralph: ...` prefix) **only if the
   relevant tests/linters/builds pass**. On failure it stashes the WIP,
   marks the task on the issue with `<!-- blocked: ... -->`, records an
   empty marker commit, and the loop stops.
4. After the agent returns, the script enforces two invariants itself
   (so the prompt isn't the only thing standing between you and a bad
   commit):
   - **HEAD must advance.** If the agent didn't commit anything, the
     loop aborts so you can inspect.
   - **`RALPH_TEST_CMD` must pass** (when set). The loop re-runs your
     verification command against the new HEAD and aborts if it fails.
5. A blocked task keeps its `- [ ]` but is excluded from the pending
   count, so the loop terminates instead of spinning on the same task.

## Safety notes

- `--allow-all-tools` lets Copilot run any shell command without prompting.
  Only run this in a directory you trust. A disposable git branch or a
  container is ideal.
- The agent commits on every iteration. Review with `git log --oneline`
  and `git diff HEAD~N` afterwards; revert with `git reset --hard` if a
  run goes off the rails.
- Transcripts in `logs/` capture each iteration verbatim -- handy for
  postmortems and for tuning your prompt or issue tasks.

## Where to go from here

- Replace the Ctrl+C gate with a CI-style check (`pytest`, `npm test`,
  `cargo test`) that must pass before the next iteration starts.
- Use `gh issue list --label ralph` to find issues to drive the loop with.
- Combine with `--mode autopilot` inside each iteration if you want the
  agent to push harder before returning.
