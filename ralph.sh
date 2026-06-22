#!/usr/bin/env bash
# Ralph loop driver for GitHub Copilot CLI.
#
# Tasks always come from a GitHub issue's checklist. Each run:
#   1. Runs an interactive planning pass so Copilot can refine the issue's
#      task list and ask the user clarifying questions.
#   2. For each remaining "- [ ]" task, spawns a fresh, non-interactive
#      `copilot` process (clean context) that implements the FIRST task,
#      runs tests, checks it off on the issue, and commits.
#   3. The loop pauses for a Ctrl+C gate (unless GATE=0) and continues until
#      no unchecked tasks remain.

set -euo pipefail

LOG_DIR="${LOG_DIR:-logs}"
MODEL="${MODEL:-}"
MAX_ITERS="${MAX_ITERS:-50}"       # 0 = unlimited
GATE="${GATE:-0}"                  # 1 = wait for Enter between iterations
EFFORT="${EFFORT:-max}"            # none|low|medium|high|xhigh|max
RALPH_TEST_CMD="${RALPH_TEST_CMD:-}"  # e.g. "pytest -q" or "npm test --silent"

# The task checklist always lives in a GitHub issue, supplied as the first
# positional argument or via the ISSUE_LINK env var.
ISSUE_LINK="${1:-${ISSUE_LINK:-}}"

if [ -z "$ISSUE_LINK" ]; then
  echo "ralph: no issue given. Pass a GitHub issue link/number as the first" >&2
  echo "ralph: argument (or set ISSUE_LINK). Tasks are read from the issue." >&2
  echo "ralph: usage: ./ralph.sh <issue-link-or-number>" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ralph: 'gh' CLI not found. Install it to read issues." >&2
  exit 1
fi
if ! gh issue view "$ISSUE_LINK" --json body -q .body >/dev/null 2>&1; then
  echo "ralph: cannot read issue '$ISSUE_LINK' via gh. Check the link and 'gh auth status'." >&2
  exit 1
fi

if ! command -v copilot >/dev/null 2>&1; then
  echo "ralph: 'copilot' is not on PATH. Install GitHub Copilot CLI first." >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ralph: not a git repo. Run: git init && git add . && git commit -m 'init'" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ralph: working tree is dirty. Commit or stash before starting the loop." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

read -r -d '' PROMPT <<'PROMPT' || true
You are running inside a Ralph loop. Each invocation starts with a fresh
context, so you cannot rely on memory of previous turns -- only on the
repository state and the referenced GitHub issue's task list.

The task checklist lives in a GitHub issue. Read it with:
  gh issue view __ISSUE_LINK__

Do exactly this, once:

1. Read the issue body with `gh issue view __ISSUE_LINK__`.
2. Pick the FIRST task whose line begins with "- [ ]".
3. Implement ONLY that task. Keep the change focused; do not refactor
   unrelated code.
4. Run the project's tests, linters, and build steps that apply to your
   change. Treat ANY failure as "not done" -- do not paper over it by
   weakening tests or skipping checks.

5. SUCCESS PATH (every relevant check passes):
   a. Update the issue's task list to change the leading "- [ ]" on that
      single line to "- [x]". Fetch the current body, edit ONLY that one
      line, and write it back:
        gh issue view __ISSUE_LINK__ --json body -q .body > /tmp/ralph-issue.md
        # edit the single line in /tmp/ralph-issue.md
        gh issue edit __ISSUE_LINK__ --body-file /tmp/ralph-issue.md
      Do not modify any other task lines.
   b. Stage and commit your code changes on the current branch with a concise
      message starting with "ralph: " that names the task you completed.

6. BLOCKED PATH (a check fails and you cannot fix it within this turn,
   or the task is ambiguous):
   a. Do NOT commit broken or unverified code to the current branch.
   b. Stash any working changes so they are not lost:
      `git stash push -u -m "ralph-blocked: <task slug>"`.
   c. Update the issue's task list to append ` <!-- blocked: <one-line
      reason> -->` to the task line, leaving its "[ ]" intact, using the
      same gh issue edit flow as above.
   d. Record the block in git with an empty marker commit:
      `git commit --allow-empty -m "ralph: blocked <one-line reason>"`.
   e. Stop. The loop will detect the blocked marker and exit.

Hard rules:
- Never commit failing code to the current branch.
- Do not edit ralph.sh.
- Do not modify task lines other than the one you are working on.
- Do not add new tasks to the issue unless it explicitly tells you to.
- You MUST advance HEAD this turn (either a success commit or a blocked
  commit). The loop treats an unchanged HEAD as a hard failure.
PROMPT
PROMPT="${PROMPT//__ISSUE_LINK__/$ISSUE_LINK}"

# Emit the current task checklist from the GitHub issue.
task_source() {
  gh issue view "$ISSUE_LINK" --json body -q .body 2>/dev/null
}

pending_count() {
  # Pending = lines starting with "- [ ]" that are NOT marked blocked.
  local n
  n=$(task_source | grep -E '^[[:space:]]*-[[:space:]]*\[ \]' \
        | grep -vc '<!-- blocked' || true)
  echo "${n:-0}"
}

# Human-readable label for where tasks come from, used in status messages.
TASK_SRC_LABEL="issue $ISSUE_LINK"

# ----------------------------------------------------------------------------
# Planning pass (interactive). Always runs before the loop: let Copilot read
# the issue, ask the user any clarifying questions, and ensure a clean,
# ordered, step-by-step checklist exists so the loop can complete exactly one
# item per iteration.
# ----------------------------------------------------------------------------
read -r -d '' PLAN_PROMPT <<'PROMPT' || true
You are the PLANNING step of a Ralph loop. You are NOT implementing anything
this turn. Your job is to make sure the GitHub issue contains a clear,
ordered, step-by-step task list that a fresh agent (with no memory of this
session) can execute ONE item per iteration.

The task list lives in this GitHub issue:
  gh issue view __ISSUE_LINK__

Do this:

1. Read the issue with `gh issue view __ISSUE_LINK__` and skim the repository
   (README, build/manifest files, source, and tests) to understand the
   project and what the issue is asking for.
2. If anything about the desired outcome is ambiguous or underspecified, USE
   THE ask_user TOOL to ask the user concise clarifying questions BEFORE
   writing tasks. Incorporate their answers.
3. Ensure the issue body contains a checklist of "- [ ]" tasks where:
   - Each task is a single, self-contained step completable in one iteration.
   - Tasks are ordered so earlier ones unblock later ones.
   - Together they FULLY cover everything the issue asks for (setup,
     implementation, tests, and any docs/config the work needs).
   - Each task line carries enough detail (files, expected behavior,
     acceptance criteria) for a fresh agent to act on it.
   - If tasks already exist, refine and extend them instead of duplicating:
     fill gaps and add missing context. If none exist, write them.
4. Write the finalized checklist (plus any supporting context) back to the
   issue body:
     gh issue view __ISSUE_LINK__ --json body -q .body > /tmp/ralph-plan.md
     # edit /tmp/ralph-plan.md so it contains the full task list + context
     gh issue edit __ISSUE_LINK__ --body-file /tmp/ralph-plan.md

Hard rules:
- Do NOT implement any task or write code this turn.
- Do NOT mark any task "- [x]".
- Do NOT edit ralph.sh.
- Keep each task small enough that exactly one fits in a single iteration.
PROMPT
PLAN_PROMPT="${PLAN_PROMPT//__ISSUE_LINK__/$ISSUE_LINK}"

printf '\n=== ralph planning (%s) ===\n' "$TASK_SRC_LABEL"
echo "ralph: Copilot will review the tasks and may ask you clarifying"
echo "ralph: questions. Answer them, then exit the session (/exit) to start"
echo "ralph: the loop."

plan_args=(-i "$PLAN_PROMPT" --allow-all-tools)
[ -n "$MODEL" ]  && plan_args+=(--model "$MODEL")
[ -n "$EFFORT" ] && plan_args+=(--effort "$EFFORT")

if ! copilot "${plan_args[@]}"; then
  echo "ralph: planning step exited non-zero. Stopping." >&2
  exit 1
fi

if [ "$(pending_count)" -eq 0 ]; then
  echo "ralph: planning produced no pending tasks in $TASK_SRC_LABEL. Nothing to do." >&2
  exit 0
fi

iter=0
while [ "$(pending_count)" -gt 0 ]; do
  iter=$((iter + 1))
  if [ "$MAX_ITERS" -gt 0 ] && [ "$iter" -gt "$MAX_ITERS" ]; then
    echo "ralph: reached MAX_ITERS=$MAX_ITERS, stopping."
    break
  fi

  ts="$(date +%Y%m%d-%H%M%S)"
  log="$LOG_DIR/run-${ts}.md"
  prev_head="$(git rev-parse HEAD)"

  printf '\n=== ralph iteration %d (%s) ===\n' "$iter" "$ts"
  echo "transcript -> $log"

  args=(
    -p "$PROMPT"
    --allow-all-tools
    --no-ask-user
    --share "$log"
    -s
  )
  [ -n "$MODEL" ]  && args+=(--model "$MODEL")
  [ -n "$EFFORT" ] && args+=(--effort "$EFFORT")

  if ! copilot "${args[@]}"; then
    echo "ralph: copilot exited non-zero on iteration $iter. Stopping." >&2
    exit 1
  fi

  new_head="$(git rev-parse HEAD)"
  if [ "$prev_head" = "$new_head" ]; then
    echo "ralph: HEAD did not advance this iteration. Agent made no commit." >&2
    echo "ralph: Stopping so you can inspect the working tree." >&2
    exit 1
  fi

  echo
  git --no-pager log -1 --oneline

  # Defense-in-depth: re-run the project's verification command ourselves.
  # If the agent committed broken code despite the prompt, this catches it
  # and stops the loop before more bad commits pile up.
  if [ -n "$RALPH_TEST_CMD" ]; then
    echo "ralph: verifying HEAD with: $RALPH_TEST_CMD"
    if ! bash -c "$RALPH_TEST_CMD"; then
      echo "ralph: verification FAILED at $(git rev-parse --short HEAD)." >&2
      echo "ralph: To undo the bad commit: git reset --hard $prev_head" >&2
      exit 1
    fi
  fi

  # Commit the iteration's transcript log so the loop history is preserved
  # in git. Only runs after a successful agent commit and verification.
  if [ -f "$log" ]; then
    git add -- "$log"
    if ! git diff --cached --quiet -- "$log"; then
      git commit -m "ralph: log for iteration $iter ($(git rev-parse --short "$new_head"))" -- "$log"
    fi
  else
    echo "ralph: no transcript at $log to commit (skipping log commit)." >&2
  fi

  remaining="$(pending_count)"
  echo "ralph: $remaining pending task(s) in $TASK_SRC_LABEL (blocked tasks are not counted)"

  if [ "$GATE" = "1" ] && [ "$remaining" -gt 0 ]; then
    if ! read -r -p "ralph: continue? [Enter=yes, Ctrl+C=stop] " _; then
      echo
      exit 0
    fi
  fi
done

echo
echo "ralph: done. No pending (unblocked) '- [ ]' items remain in $TASK_SRC_LABEL."

# If all tasks are complete and we're on a feature branch, push and open a PR.
if [ "$(pending_count)" -eq 0 ]; then
  branch="$(git symbolic-ref --short HEAD)"
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "ralph: on $branch — skipping push/PR (create a feature branch first)." >&2
  else
    echo "ralph: pushing branch '$branch' and opening PR..."
    git push -u origin "$branch"
    # Link the PR to the issue so merging closes it.
    gh pr create --fill --body "closes: $ISSUE_LINK"
    echo "ralph: PR opened."
  fi
fi
