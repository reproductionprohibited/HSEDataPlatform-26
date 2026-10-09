#!/usr/bin/env bash
# Запускать на edge. Скрипт записывает конфиги под пользователем hadoop,
# затем открывает shell; Ctrl+D возвращает с удалённого узла на edge.

set -euo pipefail

HADOOP_USER="${HADOOP_USER:-hadoop}"
SSH_USER="${SSH_USER:-$USER}"
HADOOP_HOME="${HADOOP_HOME:-/home/hadoop/hadoop}"
HOSTS=("team-15-00" "team-15-01")

# Этот блок выполняется на каждом узле от имени hadoop.
read -r -d '' CONFIG_SCRIPT <<'REMOTE' || true
set -euo pipefail
HADOOP_HOME="${HADOOP_HOME:-/home/hadoop/hadoop}"
CONF_DIR="$HADOOP_HOME/etc/hadoop"

if [[ ! -d "$CONF_DIR" ]]; then
    echo "Не найдена директория конфигов: $CONF_DIR" >&2
    echo "Задай правильный HADOOP_HOME при запуске скрипта." >&2
    exit 1
fi

cat > "$CONF_DIR/core-site.xml" <<'XML'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://team-15-nn:9000</value>
    </property>
</configuration>
XML

cat > "$CONF_DIR/hdfs-site.xml" <<'XML'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
XML

echo "Конфиги записаны в $CONF_DIR"
REMOTE

# Настраиваем edge локально и возвращаемся в обычный shell.
echo "=== EDGE: записываю конфиги ==="
printf -v CONFIG_B64 '%s' "$(printf '%s' "$CONFIG_SCRIPT" | base64 | tr -d '\n')"
sudo -iu "$HADOOP_USER" env HADOOP_HOME="$HADOOP_HOME" bash -lc "printf '%s' '$CONFIG_B64' | base64 -d | bash"

# На каждом узле записываем конфиги, затем оставляем интерактивный shell.
# Ctrl+D завершает shell пользователя hadoop и SSH, после чего цикл идёт дальше.
for host in "${HOSTS[@]}"; do
    echo
    echo "=== SSH -> ${host}: записываю конфиги ==="
    ssh -t "${SSH_USER}@${host}" \
        "sudo -iu '${HADOOP_USER}' env HADOOP_HOME='${HADOOP_HOME}' bash -lc \"printf '%s' '${CONFIG_B64}' | base64 -d | bash && exec bash -l\""
done

echo
echo "Готово. Проверь workers на edge и запускай start-dfs.sh от пользователя hadoop."
