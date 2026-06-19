#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/dotskill"
declare -a SELECTORS=()
declare -a SKILLS_TO_COPY=()
SYMLINK=0

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

usage_for_tool() {
  local tool_display_name="$1"

  cat <<EOF
Usage:
  $(basename "$0") [--global] [selector ...]
  $(basename "$0") --project-location <path> [selector ...]

Installs the shared skills for ${tool_display_name}.

Selectors can be either:
- a group folder under dotskill/ (for example: workflow)
- an individual skill name (for example: excalidraw)

If no selector is provided, all skills are installed.
If no mode is provided, global install is used.

Options:
  --global                   Install into the tool's global folder
  --project-location <path>  Install into a project-local folder
  --symlink                  Create symlinks instead of copying (live updates from dotskill/)
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
  SELECTORS=()
  SYMLINK=0
  local project_location=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --global)
        [ -z "$INSTALL_MODE" ] || [ "$INSTALL_MODE" = "global" ] || fail "Pass either --global or --project-location, not both"
        INSTALL_MODE="global"
        shift
        ;;
      --project-location)
        [ -z "$INSTALL_MODE" ] || [ "$INSTALL_MODE" = "project" ] || fail "Pass either --global or --project-location, not both"
        [ $# -ge 2 ] || fail "--project-location requires a path"
        INSTALL_MODE="project"
        project_location="$2"
        shift 2
        ;;
      --symlink)
        SYMLINK=1
        shift
        ;;
      -h|--help)
        usage_for_tool "$TOOL_DISPLAY_NAME"
        exit 0
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do
          SELECTORS+=("$1")
          shift
        done
        break
        ;;
      -*)
        fail "Unknown argument: $1"
        ;;
      *)
        SELECTORS+=("$1")
        shift
        ;;
    esac
  done

  [ -n "$INSTALL_MODE" ] || INSTALL_MODE="global"

  if [ "$INSTALL_MODE" = "global" ]; then
    TARGET_ROOT="$TOOL_GLOBAL_DIR"
  else
    mkdir -p "$project_location"
    project_location="$(CDPATH= cd -- "$project_location" && pwd)"
    TARGET_ROOT="$project_location/$TOOL_PROJECT_SUBDIR"
  fi
}

add_skill_dir_if_missing() {
  local skill_dir="$1"
  local existing=""

  for existing in "${SKILLS_TO_COPY[@]-}"; do
    [ "$existing" = "$skill_dir" ] && return
  done

  SKILLS_TO_COPY+=("$skill_dir")
}

add_all_skills() {
  local group_dir=""
  local child_dir=""

  for group_dir in "$SOURCE_DIR"/*; do
    [ -d "$group_dir" ] || continue

    if [ -f "$group_dir/SKILL.md" ]; then
      add_skill_dir_if_missing "$group_dir"
      continue
    fi

    for child_dir in "$group_dir"/*; do
      [ -d "$child_dir" ] || continue
      [ -f "$child_dir/SKILL.md" ] || continue
      add_skill_dir_if_missing "$child_dir"
    done
  done
}

add_group_skills() {
  local group_name="$1"
  local group_dir="$SOURCE_DIR/$group_name"
  local child_dir=""
  local found_any=0

  [ -d "$group_dir" ] || return 1

  if [ -f "$group_dir/SKILL.md" ]; then
    add_skill_dir_if_missing "$group_dir"
    return 0
  fi

  for child_dir in "$group_dir"/*; do
    [ -d "$child_dir" ] || continue
    [ -f "$child_dir/SKILL.md" ] || continue
    add_skill_dir_if_missing "$child_dir"
    found_any=1
  done

  [ "$found_any" -eq 1 ]
}

add_skill_by_name() {
  local skill_name="$1"
  local group_dir=""
  local candidate=""
  local matches=0

  for group_dir in "$SOURCE_DIR"/*; do
    [ -d "$group_dir" ] || continue

    candidate="$group_dir/$skill_name"
    if [ -d "$candidate" ] && [ -f "$candidate/SKILL.md" ]; then
      matches=$((matches + 1))
      add_skill_dir_if_missing "$candidate"
    fi
  done

  if [ "$matches" -gt 1 ]; then
    fail "Selector '$skill_name' is ambiguous across multiple groups"
  fi

  [ "$matches" -eq 1 ]
}

resolve_skills_to_copy() {
  local selector=""

  SKILLS_TO_COPY=()

  if [ "${#SELECTORS[@]}" -eq 0 ]; then
    add_all_skills
    return
  fi

  for selector in "${SELECTORS[@]-}"; do
    add_group_skills "$selector" && continue
    add_skill_by_name "$selector" && continue
    fail "Unknown selector '$selector'. Use a group folder or a skill name."
  done
}

copy_skills_into_target() {
  local target_root="$1"
  local skill_dir=""
  local skill_name=""

  mkdir -p "$target_root"
  resolve_skills_to_copy

  [ "${#SKILLS_TO_COPY[@]}" -gt 0 ] || fail "No skills resolved for installation"

  for skill_dir in "${SKILLS_TO_COPY[@]-}"; do

    skill_name="$(basename "$skill_dir")"
    rm -rf "$target_root/$skill_name"
    if [ "$SYMLINK" -eq 1 ]; then
      ln -sfn "$skill_dir" "$target_root/$skill_name"
    else
      mkdir -p "$target_root/$skill_name"
      cp -R "$skill_dir"/. "$target_root/$skill_name"/
    fi
  done
}

install_tool() {
  local tool="$1"
  shift

  require_source_dir
  parse_install_args "$tool" "$@"
  copy_skills_into_target "$TARGET_ROOT"

  if [ "$SYMLINK" -eq 1 ]; then
    printf 'Symlinked %s skills into %s\n' "$TOOL_DISPLAY_NAME" "$TARGET_ROOT"
  else
    printf 'Installed %s skills into %s\n' "$TOOL_DISPLAY_NAME" "$TARGET_ROOT"
  fi
}
