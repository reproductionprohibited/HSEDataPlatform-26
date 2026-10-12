#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install-java.sh"
SSH_KEY="$HOME/.ssh/team_internal"

if [[ "$(whoami)" != "team" || "$(hostname)" != "team-15-en" ]]; then
  echo "Надо запускать под team на team-15-en."
  exit 1
fi

if [[ ! -r "$INSTALL_SCRIPT" ]]; then
  echo "Недоступен скрипт: $INSTALL_SCRIPT"
  exit 1
fi

if [[ ! -r "$SSH_KEY" ]]; then
  echo "Недоступен SSH-ключ: $SSH_KEY"
  exit 1
fi

echo "Устанавливаем Java на team-15-en..."
sudo -n bash "$INSTALL_SCRIPT"

for node in team-15-nn team-15-00 team-15-01; do
  echo "Устанавливаем Java на $node..."

  ssh \
    -i "$SSH_KEY" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 \
    "team@$node" 'sudo -n bash -s' < "$INSTALL_SCRIPT"
done

echo "Java установлена на всех четырех узлах."
