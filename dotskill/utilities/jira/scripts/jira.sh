#!/usr/bin/env bash
#
# jira.sh — thin curl wrapper for JIRA Server / Data Center REST API v2.
#
# Reads connection details from the environment:
#   JIRA_BASE_URL   e.g. https://jira.example.com/   (required)
#   JIRA_API_TOKEN  Personal Access Token or password  (required)
#   JIRA_AUTH_TYPE  "bearer" (PAT) | "basic" (user:token)  (default: bearer)
#
# For JIRA_AUTH_TYPE=basic, JIRA_API_TOKEN must be "email:token" (or "user:password").
#
# Usage:
#   jira.sh get <ISSUE-KEY> [field,field,...]    # show one issue
#   jira.sh raw <ISSUE-KEY>                       # full issue JSON
#   jira.sh search '<JQL>' [maxResults]           # run a JQL search
#   jira.sh comments <ISSUE-KEY>                  # list comments
#   jira.sh comment <ISSUE-KEY> '<text>'          # add a comment   (WRITE)
#   jira.sh transitions <ISSUE-KEY>               # list available transitions
#   jira.sh transition <ISSUE-KEY> <id>           # move issue      (WRITE)
#   jira.sh assign <ISSUE-KEY> <username>         # assign issue    (WRITE)
#   jira.sh myself                                # who am I (auth check)
#   jira.sh api <METHOD> <path> [json-body]       # escape hatch: raw REST call
#
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

: "${JIRA_BASE_URL:?JIRA_BASE_URL is not set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN is not set}"
AUTH_TYPE="${JIRA_AUTH_TYPE:-bearer}"
BASE="${JIRA_BASE_URL%/}"

# Build auth args for curl.
auth_args=()
case "$AUTH_TYPE" in
  bearer) auth_args=(-H "Authorization: Bearer ${JIRA_API_TOKEN}") ;;
  basic)  auth_args=(-u "${JIRA_API_TOKEN}") ;;
  *) die "Unknown JIRA_AUTH_TYPE '$AUTH_TYPE' (expected 'bearer' or 'basic')" ;;
esac

# Wrapped curl. -k tolerates the corporate SSL-inspection proxy.
# Captures HTTP status; on >=400 prints body + status and exits non-zero.
jcurl() {
  local method="$1"; shift
  local path="$1"; shift
  local url="${BASE}${path}"
  local resp http
  resp="$(curl -sS -k -w $'\n%{http_code}' -X "$method" \
            "${auth_args[@]}" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            "$@" "$url")"
  http="${resp##*$'\n'}"
  local body="${resp%$'\n'*}"
  if [ "$http" -ge 400 ]; then
    echo "$body" >&2
    die "HTTP $http from $method $path"
  fi
  printf '%s' "$body"
}

# Pretty-print JSON if python3 is present, else raw.
pp() { if command -v python3 >/dev/null 2>&1; then python3 -m json.tool; else cat; fi; }

cmd="${1:-}"; shift || true

case "$cmd" in
  myself)
    jcurl GET "/rest/api/2/myself" | pp
    ;;

  get)
    key="${1:?usage: get <ISSUE-KEY> [fields]}"
    fields="${2:-summary,status,issuetype,priority,assignee,reporter,created,updated,labels,components}"
    jcurl GET "/rest/api/2/issue/${key}?fields=${fields}" | python3 -c '
import sys, json
d = json.load(sys.stdin); f = d["fields"]
def g(o,*ks):
    for k in ks:
        o = (o or {}).get(k) if isinstance(o, dict) else None
    return o
print("Key:       " + str(d.get("key")))
print("Summary:   " + str(f.get("summary")))
print("Type:      " + str(g(f,"issuetype","name")))
print("Status:    " + str(g(f,"status","name")))
print("Priority:  " + str(g(f,"priority","name")))
print("Assignee:  " + str(g(f,"assignee","displayName") or "Unassigned"))
print("Reporter:  " + str(g(f,"reporter","displayName")))
print("Labels:    " + (", ".join(f.get("labels") or []) or "-"))
print("Created:   " + str(f.get("created")))
print("Updated:   " + str(f.get("updated")))
desc = f.get("description")
if desc: print("\nDescription:\n" + str(desc))
'
    ;;

  raw)
    key="${1:?usage: raw <ISSUE-KEY>}"
    jcurl GET "/rest/api/2/issue/${key}" | pp
    ;;

  search)
    jql="${1:?usage: search '<JQL>' [maxResults]}"
    max="${2:-20}"
    body="$(python3 -c 'import json,sys; print(json.dumps({"jql":sys.argv[1],"maxResults":int(sys.argv[2]),"fields":["summary","status","issuetype","assignee"]}))' "$jql" "$max")"
    jcurl POST "/rest/api/2/search" --data "$body" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print("Total: %s  (showing %d)\n" % (d.get("total"), len(d.get("issues", []))))
for i in d.get("issues", []):
    f = i["fields"]
    st = (f.get("status") or {}).get("name","?")
    asg = (f.get("assignee") or {}).get("displayName","Unassigned")
    print("%-14s %-14s %-24s %s" % (i["key"], st, asg, f.get("summary")))
'
    ;;

  comments)
    key="${1:?usage: comments <ISSUE-KEY>}"
    jcurl GET "/rest/api/2/issue/${key}/comment" | python3 -c '
import sys, json
for c in json.load(sys.stdin).get("comments", []):
    who = (c.get("author") or {}).get("displayName","?")
    print("--- %s  (%s) ---" % (who, c.get("created")))
    print(c.get("body",""))
    print()
'
    ;;

  comment)
    key="${1:?usage: comment <ISSUE-KEY> '<text>'}"
    text="${2:?usage: comment <ISSUE-KEY> '<text>'}"
    body="$(python3 -c 'import json,sys; print(json.dumps({"body":sys.argv[1]}))' "$text")"
    jcurl POST "/rest/api/2/issue/${key}/comment" --data "$body" >/dev/null
    echo "Comment added to ${key}."
    ;;

  transitions)
    key="${1:?usage: transitions <ISSUE-KEY>}"
    jcurl GET "/rest/api/2/issue/${key}/transitions" | python3 -c '
import sys, json
for t in json.load(sys.stdin).get("transitions", []):
    print("%-6s -> %s  (to: %s)" % (t["id"], t["name"], (t.get("to") or {}).get("name")))
'
    ;;

  transition)
    key="${1:?usage: transition <ISSUE-KEY> <transition-id>}"
    tid="${2:?usage: transition <ISSUE-KEY> <transition-id>}"
    body="$(python3 -c 'import json,sys; print(json.dumps({"transition":{"id":sys.argv[1]}}))' "$tid")"
    jcurl POST "/rest/api/2/issue/${key}/transitions" --data "$body" >/dev/null
    echo "Issue ${key} transitioned (id ${tid})."
    ;;

  assign)
    key="${1:?usage: assign <ISSUE-KEY> <username>}"
    user="${2:?usage: assign <ISSUE-KEY> <username>}"
    body="$(python3 -c 'import json,sys; print(json.dumps({"name":sys.argv[1]}))' "$user")"
    jcurl PUT "/rest/api/2/issue/${key}/assignee" --data "$body" >/dev/null
    echo "Issue ${key} assigned to ${user}."
    ;;

  api)
    method="${1:?usage: api <METHOD> <path> [json-body]}"
    path="${2:?usage: api <METHOD> <path> [json-body]}"
    if [ "${3:-}" != "" ]; then
      jcurl "$method" "$path" --data "$3" | pp
    else
      jcurl "$method" "$path" | pp
    fi
    ;;

  ""|-h|--help|help)
    sed -n '2,40p' "$0"
    ;;

  *)
    die "Unknown command '$cmd'. Run 'jira.sh help'."
    ;;
esac
