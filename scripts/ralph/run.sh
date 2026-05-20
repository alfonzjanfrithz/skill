#!/usr/bin/env bash
# Ralph driver: build a prompt from issues/<ticket-id>/, recent commits, and
# ralph's workflow files, then hand it to a CLI agent (cursor-agent or
# opencode) in non-interactive mode. Loops until the agent emits
# <promise>NO MORE TASKS</promise> or --once is set.
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)"

AGENT="cursor"
ONCE=0
ECHO_ONLY=0
TICKET_ID=""

usage() {
  cat <<EOF
Usage:
  $(basename "$0") --ticket-id <id> [--agent cursor|opencode] [--once] [--echo] [-h|--help]

Drives a CLI agent through Ralph's prompt loop for a single ticket.

Required:
  --ticket-id <id>   The ticket directory under issues/ (e.g. EOL-12312)

Options:
  --agent <name>     Which agent CLI to drive. cursor (default) | opencode
  --once             Run a single iteration, then exit
  --echo             Print the assembled prompt to stdout and exit (no agent)
  -h, --help         Show this help

Prerequisites:
  - The chosen agent CLI must be installed and on \$PATH
      cursor   -> cursor-agent
      opencode -> opencode
  - Skills must be installed for the agent. See scripts/install/README.md
  - Must be run from inside the repo, on a non-main/master branch
  - Issues must exist under issues/<ticket-id>/NNN-*.md (created by breakdown)
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --ticket-id)
        [ $# -ge 2 ] || die "--ticket-id requires a value"
        TICKET_ID="$2"
        shift 2
        ;;
      --agent)
        [ $# -ge 2 ] || die "--agent requires a value (cursor|opencode)"
        AGENT="$2"
        shift 2
        ;;
      --once)
        ONCE=1
        shift
        ;;
      --echo)
        ECHO_ONLY=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  case "$AGENT" in
    cursor|opencode) ;;
    *) die "Unsupported --agent: $AGENT (use cursor or opencode)" ;;
  esac

  if [ -z "$TICKET_ID" ] && [ "$ECHO_ONLY" -eq 0 ]; then
    die "--ticket-id is required. Use --echo to print the prompt without a ticket."
  fi
}

require_agent_installed() {
  case "$AGENT" in
    cursor)
      command -v cursor-agent >/dev/null 2>&1 \
        || die "cursor-agent not found on \$PATH. Install it from https://cursor.com/cli"
      ;;
    opencode)
      command -v opencode >/dev/null 2>&1 \
        || die "opencode not found on \$PATH. Install it from https://opencode.ai"
      ;;
  esac
}

check_branch() {
  local branch
  branch=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null) \
    || die "Not inside a git repository"
  case "$branch" in
    main|master)
      die "Refusing to run ralph on branch '$branch'. Switch to a feature branch first."
      ;;
  esac
}

gather_issues() {
  local ticket_dir="$REPO_ROOT/issues/$TICKET_ID"
  local file
  local output=""

  if [ ! -d "$ticket_dir" ]; then
    echo "No ticket directory found: $ticket_dir"
    return
  fi

  for file in "$ticket_dir"/*.md; do
    [ -e "$file" ] || continue
    local basename
    basename=$(basename "$file")
    output+="\n=== $basename ===\n"
    output+=$(cat "$file")
    output+="\n"
  done

  if [ -z "$output" ]; then
    echo "No open issues found in $ticket_dir"
  else
    printf '%s' "$output"
  fi
}

build_prompt() {
  local issues commits prompt feedback_loops git_commit

  if [ -n "$TICKET_ID" ]; then
    issues=$(gather_issues)
  else
    issues="No ticket specified (--echo mode)"
  fi

  commits=$(git -C "$REPO_ROOT" log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")
  prompt=$(cat "$SCRIPT_DIR/prompt.md")
  feedback_loops=$(cat "$SCRIPT_DIR/feedback-loops.md")
  git_commit=$(cat "$SCRIPT_DIR/git-commit.md")

  cat <<EOF
Previous commits: $commits

Ticket: ${TICKET_ID:-<none>}

Issues: $issues

$prompt

$feedback_loops

$git_commit
EOF
}

run_agent() {
  local prompt="$1" logfile="$2"
  case "$AGENT" in
    cursor)
      # -p: non-interactive print mode (has access to write+shell tools)
      # --force: auto-allow commands unless explicitly denied
      cursor-agent -p --force "$prompt" 2>&1 | tee "$logfile"
      ;;
    opencode)
      opencode run "$prompt" 2>&1 | tee "$logfile"
      ;;
  esac
}

main() {
  parse_args "$@"

  if [ "$ECHO_ONLY" -eq 1 ]; then
    build_prompt
    exit 0
  fi

  require_agent_installed
  check_branch

  local ticket_dir="$REPO_ROOT/issues/$TICKET_ID"
  if [ ! -d "$ticket_dir" ]; then
    die "Ticket directory not found: $ticket_dir"
  fi

  local logs_dir="$SCRIPT_DIR/logs"
  mkdir -p "$logs_dir"

  local iter=0
  while true; do
    iter=$((iter + 1))
    local ts logfile prompt
    ts=$(date +%Y%m%d-%H%M%S)
    logfile="$logs_dir/${ts}-iter-${iter}.log"
    prompt=$(build_prompt)

    printf '\n=== Ralph iteration %d (%s) — ticket=%s — agent=%s ===\n' "$iter" "$ts" "$TICKET_ID" "$AGENT"
    printf 'Log: %s\n\n' "$logfile"

    run_agent "$prompt" "$logfile"

    if grep -q "<promise>NO MORE TASKS</promise>" "$logfile"; then
      printf '\nRalph finished: NO MORE TASKS.\n'
      break
    fi

    if [ "$ONCE" -eq 1 ]; then
      printf '\n--once set, stopping after one iteration.\n'
      break
    fi
  done
}

main "$@"
