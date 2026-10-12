#!/usr/bin/env bash
set -euo pipefail

if [[ "$(whoami)" != team || "$(hostname -s)" != team-15-en ]]; then
  echo "Запустите под team на edge team-15-en." >&2
  exit 1
fi
SSH_KEY="$HOME/.ssh/team_internal"
if [[ ! -r "$SSH_KEY" ]]; then
  echo "Недоступен ключ: $SSH_KEY" >&2
  exit 1
fi
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SSH_OPTIONS=(-i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10)
NODES=(team-15-nn team-15-00 team-15-01)
run_on_node() {
  local node="$1" command="$2"
  if [[ "$node" == team-15-en ]]; then
    bash -c "$command"
  else
    ssh "${SSH_OPTIONS[@]}" "team@$node" "$command"
  fi
}
