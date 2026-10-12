#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Нужен sudo."
  exit 1
fi

# Сохраняем исходный файл только при первом запуске.
if [[ ! -e /etc/hosts.before-hdfs ]]; then
  cp -p /etc/hosts /etc/hosts.before-hdfs
fi

# Привязываем имена к внутренним IP.
sed -i \
  -e 's/^10\.15\.0\.10[[:space:]].*/10.15.0.10 team-15-en.hse.c.mws team-15-en/' \
  -e 's/^10\.15\.0\.11[[:space:]].*/10.15.0.11 team-15-nn.hse.c.mws team-15-nn/' \
  -e 's/^10\.15\.0\.12[[:space:]].*/10.15.0.12 team-15-00.hse.c.mws team-15-00/' \
  -e 's/^10\.15\.0\.13[[:space:]].*/10.15.0.13 team-15-01.hse.c.mws team-15-01/' \
  -e '/^127\.0\.1\.1[[:space:]]*team-15-/d' \
  /etc/hosts

echo "Настроен узел: $(hostname)"
getent ahostsv4 "$(hostname)"
