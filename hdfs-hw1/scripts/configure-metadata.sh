#!/usr/bin/env bash
set -euo pipefail
# Выполнять под team на каждом из двух узлов при остановленном сервисе.
case "$(hostname -s)" in
  team-15-nn) storage=/tmp/hadoop-hadoop/dfs/name; service=NameNode ;;
  team-15-01) storage=/tmp/hadoop-hadoop/dfs/namesecondary; service=SecondaryNameNode ;;
  *) echo "Ожидается team-15-nn или team-15-01." >&2; exit 1 ;;
esac
if [[ "$(whoami)" != team ]]; then
  echo "Запустите под team, у которого есть sudo." >&2
  exit 1
fi
processes=$(sudo -iu hadoop jps -l)
if grep -qE "[[:space:]]org\.apache\.hadoop\.hdfs\.server\.namenode\.${service}$" <<< "$processes"; then
  echo "Сначала остановите $service. Конфиги не изменены." >&2
  exit 1
fi
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONF_DIR=/opt/hadoop/etc/hadoop
backup=$(sudo mktemp -d "$CONF_DIR/metadata-backup.XXXXXX")
for file in core-site.xml hdfs-site.xml; do
  sudo cp -p "$CONF_DIR/$file" "$backup/$file"
done
for file in core-site.xml hdfs-site.xml; do
  sudo install -o hadoop -g hadoop -m 0644 "$PROJECT_DIR/conf/$file" "$CONF_DIR/$file"
done
# Существующее хранилище не очищается, его содержимое не меняется.
for directory in /tmp/hadoop-hadoop /tmp/hadoop-hadoop/dfs "$storage"; do
  if [[ ! -d "$directory" ]]; then
    sudo install -d -o hadoop -g hadoop -m 0750 "$directory"
  fi
done
sudo -iu hadoop test -w "$storage"
echo "Конфиги установлены. Резервная копия: $backup"
