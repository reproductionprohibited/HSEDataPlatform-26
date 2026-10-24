#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require hadoop team-15-nn

# Скачать и распаковать Spark.
cd "$HOME"
if [[ ! -d "$SPARK_HOME" ]]; then
    wget "https://dlcdn.apache.org/spark/spark-3.5.9/$SPARK_PACKAGE.tgz"
    tar -xzf "$SPARK_PACKAGE.tgz"
fi

# Переменные окружения сохраняются в ~/.bashrc для следующих сессий.
if ! grep -q '# spark-hw4' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<EOF
# spark-hw4
export SPARK_HOME=$SPARK_HOME
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export YARN_CONF_DIR=\$HADOOP_CONF_DIR
export PATH=\$PATH:\$SPARK_HOME/bin
EOF
fi

# Скопировать конфиги из репозитория.
cp "$PROJECT_DIR/conf/hive-site.xml" "$PROJECT_DIR/conf/spark-defaults.conf" "$SPARK_HOME/conf/"

echo "Spark установлен в $SPARK_HOME"
