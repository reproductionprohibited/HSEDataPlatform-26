#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="/home/team/dist"
ARCHIVE="hadoop-3.5.0.tar.gz"
SSH_KEY="$HOME/.ssh/team_internal"

if [[ "$(whoami)" != "team" || "$(hostname)" != "team-15-en" ]]; then
  echo "Надо запускать под team на team-15-en."
  exit 1
fi

if [[ ! -r "$DIST_DIR/$ARCHIVE" ]]; then
  echo "Недоступен архив: $DIST_DIR/$ARCHIVE"
  exit 1
fi

if [[ ! -r "$DIST_DIR/$ARCHIVE.sha512" ]]; then
  echo "Недоступен файл контрольной суммы."
  exit 1
fi

if [[ ! -r "$SSH_KEY" ]]; then
  echo "Недоступен SSH-ключ: $SSH_KEY"
  exit 1
fi

SSH_OPTIONS=(
  -i "$SSH_KEY"
  -o IdentitiesOnly=yes
  -o BatchMode=yes
  -o StrictHostKeyChecking=yes
  -o ConnectTimeout=10
)

cd "$DIST_DIR"
sha512sum --check "$ARCHIVE.sha512"

for node in team-15-nn team-15-00 team-15-01; do
  echo "Передаем архив на $node..."

  ssh "${SSH_OPTIONS[@]}" "team@$node" \
    'mkdir -p /home/team/dist'

  scp "${SSH_OPTIONS[@]}" \
    "$ARCHIVE" "$ARCHIVE.sha512" \
    "team@$node:/home/team/dist/"

  echo "Проверяем архив на $node..."

  ssh "${SSH_OPTIONS[@]}" "team@$node" \
    "cd /home/team/dist && sha512sum --check '$ARCHIVE.sha512'"
done

echo "Архив Hadoop проверен на всех четырех узлах."
