#!/bin/bash
# Gather open issues from the issues/ directory
issues=$(cat issues/*.md 2>/dev/null || echo "No issues found")

# Gather recent git history for context
commits=$(git log -n 5 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No commits found")

# Load Ralph's core prompt and workflow files
prompt=$(cat ralph/prompt.md)
feedback_loops=$(cat ralph/feedback-loops.md)
git_commit=$(cat ralph/git-commit.md)

# Run Claude Code with auto-accept edits, injecting all context into the prompt
echo --permission-mode acceptEdits \
  "Previous commits: $commits

Issues: $issues

$prompt

$feedback_loops

$git_commit"
