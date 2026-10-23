#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
USER_SCRIPT="$SCRIPT_DIR/create-hadoop-user.sh"
SSH_KEY="$HOME/.ssh/team_internal"

if [[ "$(whoami)" != "team" ]]; then
  echo "Запустите скрипт под пользователем team."
  exit 1
fi

if [[ "$(hostname)" != "team-15-en" ]]; then
  echo "Запустите скрипт на edge-ноде team-15-en."
  exit 1
fi

if [[ ! -r "$USER_SCRIPT" ]]; then
  echo "Недоступен скрипт: $USER_SCRIPT"
  exit 1
fi

if [[ ! -r "$SSH_KEY" ]]; then
  echo "Недоступен SSH-ключ: $SSH_KEY"
  exit 1
fi

echo "Проверяем пользователя на team-15-en..."
sudo -n bash "$USER_SCRIPT"

for node in team-15-nn team-15-00 team-15-01; do
  echo "Проверяем пользователя на $node..."

  ssh \
    -i "$SSH_KEY" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 \
    "team@$node" 'sudo -n bash -s' < "$USER_SCRIPT"
done

echo "Пользователь hadoop подготовлен на всех четырех узлах."
