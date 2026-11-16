#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export SPARK_HOME=/home/hadoop/spark-3.5.9-bin-hadoop3
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export YARN_CONF_DIR=$HADOOP_CONF_DIR
export PATH="$SPARK_HOME/bin:/opt/hadoop/bin:$PATH"

if [[ "$(whoami)" != hadoop || "$(hostname -s)" != team-15-nn ]]; then
    echo "Запустите под пользователем hadoop на team-15-nn." >&2
    exit 1
fi
