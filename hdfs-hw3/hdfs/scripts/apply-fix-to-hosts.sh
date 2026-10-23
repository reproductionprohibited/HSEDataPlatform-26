#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FIX_SCRIPT="$SCRIPT_DIR/fix-hosts.sh"
SSH_KEY="$HOME/.ssh/team_internal"

if [[ "$(whoami)" != "team" || "$(hostname)" != "team-15-en" ]]; then
  echo "Надо запускать скрипт под team на team-15-en."
  exit 1
fi

if [[ ! -r "$FIX_SCRIPT" ]]; then
  echo "Не найден или недоступен для чтения скрипт: $FIX_SCRIPT"
  exit 1
fi

if [[ ! -r "$SSH_KEY" ]]; then
  echo "Не найден или недоступен для чтения SSH-ключ: $SSH_KEY"
  exit 1
fi

echo "Настраиваем team-15-en..."
sudo -n bash "$FIX_SCRIPT"

for node in team-15-nn team-15-00 team-15-01; do
  echo "Настраиваем $node..."

  ssh \
    -i "$SSH_KEY" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 \
    "team@$node" 'sudo -n bash -s' < "$FIX_SCRIPT"
done

echo "Настройка завершена на всех четырех узлах."
