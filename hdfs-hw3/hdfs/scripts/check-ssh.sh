#!/usr/bin/env bash
set -u

if [[ "$(whoami)" != "hadoop" ]]; then
  echo "Ошибка: нужно запускаться от пользователя hadoop."
  exit 1
fi

failed=0

for node in team-15-en team-15-nn team-15-00 team-15-01; do
  echo "Проверяем $node..."

  if ssh \
    -i "$HOME/.ssh/id_ed25519" \
    -o IdentitiesOnly=yes \
    -o PasswordAuthentication=no \
    -o KbdInteractiveAuthentication=no \
    -o ConnectTimeout=10 \
    "hadoop@$node" 'hostname; whoami'; then
    echo "$node: подключение работает"
  else
    echo "$node: ошибка подключения"
    failed=1
  fi

  echo
done

if [[ "$failed" -eq 0 ]]; then
  echo "SSH-доступ работает на всех четырех узлах."
else
  echo "Есть ошибки SSH-доступа."
fi

exit "$failed"
