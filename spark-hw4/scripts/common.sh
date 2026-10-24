#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

SPARK_PACKAGE=spark-3.5.9-bin-hadoop3

export SPARK_HOME=/home/hadoop/$SPARK_PACKAGE
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export YARN_CONF_DIR=$HADOOP_CONF_DIR
export PATH=$PATH:$SPARK_HOME/bin:/opt/hadoop/bin

require() {
    local user=$1 host=$2
    if [[ "$(whoami)" != "$user" || "$(hostname -s)" != "$host" ]]; then
        echo "Запустите под $user на $host." >&2
        exit 1
    fi
}
