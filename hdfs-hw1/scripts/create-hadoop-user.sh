#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Запустите скрипт через sudo."
  exit 1
fi

if id hadoop >/dev/null 2>&1; then
  echo "Пользователь hadoop уже существует, сохраняем настройки."
else
  adduser \
    --disabled-password \
    --gecos "" \
    --shell /bin/bash \
    hadoop

  echo "Пользователь hadoop создан."
  echo "Вход по паролю отключен; SSH-ключ настраивается отдельно."
fi

if [[ "$(id -u hadoop)" -eq 0 ]]; then
  echo "Ошибка: пользователь hadoop имеет UID 0."
  exit 1
fi

if id -nG hadoop | tr ' ' '\n' | grep -qx sudo; then
  echo "Ошибка: пользователь hadoop входит в группу sudo."
  exit 1
fi

hostname
id hadoop
