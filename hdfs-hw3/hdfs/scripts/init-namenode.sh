#!/usr/bin/env bash
set -euo pipefail
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-$HADOOP_HOME/etc/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"
HDFS="$HADOOP_HOME/bin/hdfs"
if [[ "$(whoami)" != hadoop || "$(hostname -s)" != team-15-nn ]]; then
  echo "Запустите под hadoop на team-15-nn." >&2
  exit 1
fi

NAME_DIR="$("$HDFS" getconf -confKey dfs.namenode.name.dir)"
NAME_DIR="${NAME_DIR#file://}"
if [[ "$NAME_DIR" != /tmp/hadoop-hadoop/dfs/name ]]; then
  echo "Неожиданный каталог NameNode: $NAME_DIR; проверьте конфиг." >&2
  exit 1
fi
if [[ -f "$NAME_DIR/current/VERSION" ]]; then
  echo "Метаданные уже существуют. Форматирование пропущено."
  exit 0
fi
if [[ "${1:-}" != --new-cluster || $# != 1 ]]; then
  echo "Для совершенно нового кластера: $0 --new-cluster" >&2
  exit 1
fi
processes=$(jps -l)
if grep -qE '[[:space:]]org\.apache\.hadoop\.hdfs\.server\.namenode\.NameNode$' <<< "$processes"; then
  echo "NameNode уже работает. Форматирование запрещено." >&2
  exit 1
fi
if [[ ! -d "$NAME_DIR" || ! -w "$NAME_DIR" ]]; then
  echo "Сначала выполните configure-metadata.sh под team." >&2
  exit 1
fi
contents=$(find "$NAME_DIR" -mindepth 1 -maxdepth 1 -print -quit)
if [[ -n "$contents" ]]; then
  echo "Каталог непустой. Форматирование запрещено." >&2
  exit 1
fi
"$HDFS" namenode -format -nonInteractive
