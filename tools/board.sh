#!/bin/bash
# Crown & Crucible agent coordination board helper.
# All agents share ONE live board: the copy in the main checkout (not your worktree/clone).
# Usage:
#   tools/board.sh show                                  print the whole board
#   tools/board.sh inbox  <agent>                        messages addressed to <agent> or All
#   tools/board.sh post   <from> <to> <message...>       append a message (newest at the bottom)
#   tools/board.sh claim  <agent> <path> [note...]       lock a file or folder before editing
#   tools/board.sh release <agent> <path>                release your claim when done
#   tools/board.sh claims                                list current claims
#   tools/board.sh status <agent> <state> <task...>      update your status row
#        state: idle | working | blocked | review | done
#   tools/board.sh done   <agent> <summary...>           record a handoff/finished item
# Override the board location with CC_BOARD=/path/to/AGENT_BOARD.md
set -u
BOARD="${CC_BOARD:-$HOME/GameMakerProjects/BLANK GAME/docs/AGENT_BOARD.md}"
LOCK="${BOARD}.lock"
now() { TZ=America/New_York date '+%Y-%m-%d %H:%M ET'; }
die() { echo "board: $*" >&2; exit 1; }
[ -f "$BOARD" ] || die "board not found at $BOARD"

lock() {
  local i=0
  until mkdir "$LOCK" 2>/dev/null; do
    i=$((i+1)); [ $i -gt 100 ] && die "board is locked ($LOCK); if no one is writing, remove that folder"
    sleep 0.1
  done
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
}
clean() { printf '%s' "$*" | tr '\n|' ' /'; }

# Replace the block between <!-- NAME:START --> and <!-- NAME:END --> via an awk program on its rows.
section_rows() { awk -v s="<!-- $1:START -->" -v e="<!-- $1:END -->" '$0==s{f=1;next} $0==e{f=0} f' "$BOARD"; }
rewrite_section() { # $1=name, stdin=new rows
  local tmp; tmp="$(mktemp)"; local rows; rows="$(cat)"
  ROWS="$rows" awk -v s="<!-- $1:START -->" -v e="<!-- $1:END -->" '
    $0==s {print; if (ENVIRON["ROWS"]!="") print ENVIRON["ROWS"]; skip=1; next}
    $0==e {skip=0}
    !skip {print}' "$BOARD" > "$tmp" && cat "$tmp" > "$BOARD"; rm -f "$tmp"
}
append_msg() { printf '%s\n' "- [$(now)] $1 -> $2: $(clean "$3")" >> "$BOARD"; }

cmd="${1:-show}"; shift || true
case "$cmd" in
  show) cat "$BOARD" ;;
  inbox)
    [ $# -ge 1 ] || die "usage: inbox <agent>"
    grep -iE -- "-> *($1|All|Everyone)[ ,:]" "$BOARD" | tail -n 30 ;;
  post)
    [ $# -ge 3 ] || die "usage: post <from> <to> <message...>"
    from="$1"; to="$2"; shift 2; lock; append_msg "$from" "$to" "$*"; echo "posted" ;;
  claims) section_rows CLAIMS ;;
  claim)
    [ $# -ge 2 ] || die "usage: claim <agent> <path> [note...]"
    agent="$1"; path="$2"; shift 2; note="$(clean "${*:-}")"; lock
    holder="$(section_rows CLAIMS | awk -F'|' -v p="$path" '
      function t(x){gsub(/^[ `]+|[ `]+$/,"",x);return x}
      NR>2 { c=t($3); a=t($2); if (c!="" && (index(p,c)==1 || index(c,p)==1)) {print a" ("c")"; exit} }')"
    if [ -n "$holder" ]; then
      case "$holder" in "$agent "*) echo "already yours: $holder"; exit 0 ;; esac
      die "CLAIMED by $holder - do not edit it. Post a message to that agent instead."
    fi
    { section_rows CLAIMS; echo "| $agent | \`$path\` | $(now) | $note |"; } | rewrite_section CLAIMS
    append_msg "$agent" "All" "claimed $path${note:+ ($note)}"; echo "claimed $path" ;;
  release)
    [ $# -ge 2 ] || die "usage: release <agent> <path>"
    agent="$1"; path="$2"; lock
    section_rows CLAIMS | awk -F'|' -v a="$agent" -v p="$path" '
      function t(x){gsub(/^[ `]+|[ `]+$/,"",x);return x}
      NR<=2 || !(t($2)==a && t($3)==p)' | rewrite_section CLAIMS
    append_msg "$agent" "All" "released $path"; echo "released $path" ;;
  status)
    [ $# -ge 3 ] || die "usage: status <agent> <state> <task...>"
    agent="$1"; state="$2"; shift 2; task="$(clean "$*")"; lock
    rows="$(section_rows STATUS)"
    files="$(section_rows CLAIMS | awk -F'|' -v a="$agent" 'function t(x){gsub(/^[ `]+|[ `]+$/,"",x);return x} NR>2 && t($2)==a {printf "%s`%s`", (n++?", ":""), t($3)}')"
    new="| $agent | $task | ${files:--} | $(now) | $state |"
    if printf '%s\n' "$rows" | awk -F'|' -v a="$agent" '{gsub(/^ +| +$/,"",$2)} $2==a{f=1} END{exit !f}'; then
      printf '%s\n' "$rows" | awk -F'|' -v a="$agent" -v n="$new" '{x=$2; gsub(/^ +| +$/,"",x)} x==a{print n; next} {print}' | rewrite_section STATUS
    else
      { printf '%s\n' "$rows"; echo "$new"; } | rewrite_section STATUS
    fi
    append_msg "$agent" "All" "status $state: $task"; echo "status updated" ;;
  done)
    [ $# -ge 2 ] || die "usage: done <agent> <summary...>"
    agent="$1"; shift; lock
    { section_rows DONE; echo "- [$(now)] $agent: $(clean "$*")"; } | rewrite_section DONE
    append_msg "$agent" "All" "done: $*"; echo "recorded" ;;
  *) sed -n '2,15p' "$0"; exit 1 ;;
esac
