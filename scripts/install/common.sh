#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/dotskill"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

usage_for_tool() {
  local tool_display_name="$1"

  cat <<EOF
Usage:
  $(basename "$0") --global
  $(basename "$0") --project-location <path>

Installs the shared skills for ${tool_display_name}.

Options:
  --global                   Install into the tool's global folder
  --project-location <path>  Install into a project-local folder
  -h, --help                 Show this help
EOF
}

require_source_dir() {
  [ -d "$SOURCE_DIR" ] || fail "Source skills directory not found: $SOURCE_DIR"
}

resolve_tool_paths() {
  local tool="$1"

  case "$tool" in
    cursor)
      TOOL_DISPLAY_NAME="Cursor"
      TOOL_GLOBAL_DIR="${CURSOR_GLOBAL_DIR:-$HOME/.cursor/skills}"
      TOOL_PROJECT_SUBDIR="${CURSOR_PROJECT_SUBDIR:-.cursor/skills}"
      ;;
    claude)
      TOOL_DISPLAY_NAME="Claude"
      TOOL_GLOBAL_DIR="${CLAUDE_GLOBAL_DIR:-$HOME/.claude/skills}"
      TOOL_PROJECT_SUBDIR="${CLAUDE_PROJECT_SUBDIR:-.claude/skills}"
      ;;
    opencode)
      TOOL_DISPLAY_NAME="OpenCode"
      TOOL_GLOBAL_DIR="${OPENCODE_GLOBAL_DIR:-$HOME/.config/opencode/skills}"
      TOOL_PROJECT_SUBDIR="${OPENCODE_PROJECT_SUBDIR:-.opencode/skills}"
      ;;
    copilot)
      TOOL_DISPLAY_NAME="GitHub Copilot"
      TOOL_GLOBAL_DIR="${COPILOT_GLOBAL_DIR:-$HOME/.config/github-copilot/skills}"
      TOOL_PROJECT_SUBDIR="${COPILOT_PROJECT_SUBDIR:-.github/copilot/skills}"
      ;;
    *)
      fail "Unsupported tool: $tool"
      ;;
  esac
}

parse_install_args() {
  local tool="$1"
  shift

  resolve_tool_paths "$tool"

  INSTALL_MODE=""
  TARGET_ROOT=""
  local project_location=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --global)
        [ -z "$INSTALL_MODE" ] || fail "Pass either --global or --project-location, not both"
        INSTALL_MODE="global"
        shift
        ;;
      --project-location)
        [ -z "$INSTALL_MODE" ] || fail "Pass either --global or --project-location, not both"
        [ $# -ge 2 ] || fail "--project-location requires a path"
        INSTALL_MODE="project"
        project_location="$2"
        shift 2
        ;;
      -h|--help)
        usage_for_tool "$TOOL_DISPLAY_NAME"
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  [ -n "$INSTALL_MODE" ] || fail "Pass --global or --project-location <path>"

  if [ "$INSTALL_MODE" = "global" ]; then
    TARGET_ROOT="$TOOL_GLOBAL_DIR"
  else
    mkdir -p "$project_location"
    project_location="$(CDPATH= cd -- "$project_location" && pwd)"
    TARGET_ROOT="$project_location/$TOOL_PROJECT_SUBDIR"
  fi
}

copy_skills_into_target() {
  local target_root="$1"
  local skill_dir=""
  local skill_name=""

  mkdir -p "$target_root"

  for skill_dir in "$SOURCE_DIR"/*; do
    [ -d "$skill_dir" ] || continue

    skill_name="$(basename "$skill_dir")"
    rm -rf "$target_root/$skill_name"
    mkdir -p "$target_root/$skill_name"
    cp -R "$skill_dir"/. "$target_root/$skill_name"/
  done
}

install_tool() {
  local tool="$1"
  shift

  require_source_dir
  parse_install_args "$tool" "$@"
  copy_skills_into_target "$TARGET_ROOT"

  printf 'Installed %s skills into %s\n' "$TOOL_DISPLAY_NAME" "$TARGET_ROOT"
}

