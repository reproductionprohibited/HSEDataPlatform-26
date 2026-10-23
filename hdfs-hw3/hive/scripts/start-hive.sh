#!/usr/bin/env bash
set -euo pipefail

export HIVE_HOME=/opt/hive
export HIVE_CONF_DIR=/opt/hive/conf
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_OPTS="${HADOOP_OPTS:-} --add-opens=java.base/java.nio=ALL-UNNAMED"

mkdir -p "$HOME/hive-logs"

port_open() {
    ss -ltnH "sport = :$1" | grep -q .
}

wait_port() {
    for ((i=0; i<45; i++)); do
        if port_open "$1"; then
            return 0
        fi
        sleep 2
    done
    echo "Порт $1 не открылся. Проверь логи в ~/hive-logs."
    return 1
}

if ! port_open 9083; then
    export HADOOP_HEAPSIZE=512
    nohup "$HIVE_HOME/bin/hive" --service metastore \
        > "$HOME/hive-logs/metastore.log" 2>&1 < /dev/null &
    wait_port 9083
fi

if ! port_open 10000; then
    export HADOOP_HEAPSIZE=768
    nohup "$HIVE_HOME/bin/hiveserver2" \
        > "$HOME/hive-logs/hiveserver2.log" 2>&1 < /dev/null &
    wait_port 10000
fi

"$HIVE_HOME/bin/beeline" \
    -u 'jdbc:hive2://127.0.0.1:10000/default' \
    -n team -e 'SELECT 1;'
