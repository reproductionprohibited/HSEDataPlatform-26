#!/usr/bin/env bash
set -euo pipefail
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-$HADOOP_HOME/etc/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"
HDFS="$HADOOP_HOME/bin/hdfs"
if [[ "$(whoami)" != hadoop || "$(hostname -s)" != team-15-01 ]]; then
  echo "Запустите под hadoop на team-15-01." >&2
  exit 1
fi

processes=$(jps -l)
if grep -qE '[[:space:]]org\.apache\.hadoop\.hdfs\.server\.namenode\.SecondaryNameNode$' <<< "$processes"; then
  echo "SecondaryNameNode уже запущен."
  exit 0
fi
"$HDFS" --daemon start secondarynamenode
for attempt in {1..15}; do
  processes=$(jps -l)
  if grep -qE '[[:space:]]org\.apache\.hadoop\.hdfs\.server\.namenode\.SecondaryNameNode$' <<< "$processes"; then
    echo "SecondaryNameNode: процесс запущен. Проверьте готовность по инструкции."
    exit 0
  fi
  sleep 2
done
echo "SecondaryNameNode не появился за время ожидания; проверьте логи." >&2
exit 1
