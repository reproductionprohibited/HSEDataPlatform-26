#!/usr/bin/env bash
# Запускать на edge. Скрипт записывает конфиги под пользователем hadoop,
# затем открывает shell; Ctrl+D возвращает с удалённого узла на edge.
#
# Топология кластера (3 DataNode):
#   Server 1  team-15-nn  Master          NameNode + DataNode
#   Server 2  team-15-00  Worker          DataNode
#   Server 3  team-15-01  Вспомогательный SecondaryNameNode + DataNode
#
# Роли определяются конфигами и файлом workers; скрипт только раскладывает их:
#   - NameNode          -> fs.defaultFS (core-site.xml)
#   - SecondaryNameNode -> dfs.namenode.secondary.http-address (hdfs-site.xml)
#   - DataNode          -> файл workers на edge (заполняется из WORKERS)

set -euo pipefail

HADOOP_USER="${HADOOP_USER:-hadoop}"
SSH_USER="${SSH_USER:-$USER}"
HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
# Узлы, на которые раскладываются конфиги. team-15-nn сюда не входит: к моменту
# запуска NameNode уже настроен, и его конфиги перезаписывать нельзя (там могут
# быть свойства NameNode, которых нет в этом скрипте). DataNode на team-15-nn
# использует уже существующий fs.defaultFS.
HOSTS=("team-15-00" "team-15-01")
# Узлы, на которых start-dfs.sh поднимет DataNode: все три сервера.
WORKERS=("team-15-nn" "team-15-00" "team-15-01")

# Этот блок выполняется на каждом узле от имени hadoop.
read -r -d '' CONFIG_SCRIPT <<'REMOTE' || true
set -euo pipefail
HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
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
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>team-15-01:9868</value>
    </property>
</configuration>
XML

echo "Конфиги записаны в $CONF_DIR"
REMOTE

# Настраиваем edge локально и возвращаемся в обычный shell.
echo "=== EDGE: записываю конфиги ==="
printf -v CONFIG_B64 '%s' "$(printf '%s' "$CONFIG_SCRIPT" | base64 | tr -d '\n')"
sudo -iu "$HADOOP_USER" env HADOOP_HOME="$HADOOP_HOME" bash -lc "printf '%s' '$CONFIG_B64' | base64 -d | bash"

# workers нужен только на edge: start-dfs.sh читает его там, где запускается.
# $HADOOP_HOME в одинарных кавычках раскрывает login-shell пользователя hadoop,
# поэтому путь берётся из его профиля (там HADOOP_HOME задан).
echo "=== EDGE: записываю workers ==="
printf '%s\n' "${WORKERS[@]}" | sudo -iu "$HADOOP_USER" env HADOOP_HOME="$HADOOP_HOME" \
    bash -lc 'cat > "$HADOOP_HOME/etc/hadoop/workers" && echo "workers записан в $HADOOP_HOME/etc/hadoop/workers:" && cat "$HADOOP_HOME/etc/hadoop/workers"'

# На каждом узле записываем конфиги, затем оставляем интерактивный shell.
# Ctrl+D завершает shell пользователя hadoop и SSH, после чего цикл идёт дальше.
# Shell возвращает код последней команды в нём, поэтому ошибку ssh не считаем
# фатальной: иначе set -e оборвал бы цикл, не дойдя до следующих узлов.
for host in "${HOSTS[@]}"; do
    echo
    echo "=== SSH -> ${host}: записываю конфиги ==="
    ssh -t "${SSH_USER}@${host}" \
        "sudo -iu '${HADOOP_USER}' env HADOOP_HOME='${HADOOP_HOME}' bash -lc \"printf '%s' '${CONFIG_B64}' | base64 -d | bash && exec bash -l\"" \
        || echo "WARN: ${host}: ssh-сессия завершилась с ошибкой, проверь конфиги на узле" >&2
done

echo
echo "Готово. Запускай start-dfs.sh на edge от пользователя hadoop."
