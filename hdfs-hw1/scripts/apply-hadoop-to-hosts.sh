#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install-hadoop.sh"
SSH_KEY="$HOME/.ssh/team_internal"

if [[ "$(whoami)" != "team" ]]; then
  echo "Ошибка: запустите скрипт под пользователем team."
  exit 1
fi

if [[ "$(hostname)" != "team-15-en" ]]; then
  echo "Ошибка: надо запускать скрипт на edge-ноде team-15-en."
  exit 1
fi

if [[ ! -r "$INSTALL_SCRIPT" ]]; then
  echo "Недоступен установщик: $INSTALL_SCRIPT"
  exit 1
fi

if [[ ! -r "$SSH_KEY" ]]; then
  echo "Недоступен SSH-ключ: $SSH_KEY"
  exit 1
fi

echo "Устанавливаем Hadoop на team-15-en..."
sudo -n bash "$INSTALL_SCRIPT"

for node in team-15-nn team-15-00 team-15-01; do
  echo "Устанавливаем Hadoop на $node..."

  ssh \
    -i "$SSH_KEY" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 \
    "team@$node" 'sudo -n bash -s' < "$INSTALL_SCRIPT"
done

echo "Hadoop установлен на всех четырех узлах."
