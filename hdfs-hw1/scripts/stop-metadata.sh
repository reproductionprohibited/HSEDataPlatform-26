#!/usr/bin/env bash
set -euo pipefail
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-$HADOOP_HOME/etc/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"
HDFS="$HADOOP_HOME/bin/hdfs"
if [[ "$(whoami)" != hadoop ]]; then
  echo "Запустите под hadoop." >&2
  exit 1
fi
case "$(hostname -s)" in
  team-15-nn) daemon=namenode ;;
  team-15-en) daemon=secondarynamenode ;;
  *) echo "Ожидается team-15-nn или team-15-en." >&2; exit 1 ;;
esac
"$HDFS" --daemon stop "$daemon"
echo "Команда остановки $daemon выполнена; хранилище сохранено."
