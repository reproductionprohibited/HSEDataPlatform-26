#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Использование: bash load-data.sh файл.csv YYYY-MM-DD"
    exit 1
fi

file=$1
day=$2

[[ -s "$file" ]] || { echo "Файл отсутствует или пуст"; exit 1; }
[[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
    echo "Дата должна быть в формате YYYY-MM-DD"
    exit 1
}

partition="/user/team/hw3/events/event_date=$day"

/opt/hadoop/bin/hdfs dfs -mkdir -p "$partition"
/opt/hadoop/bin/hdfs dfs -put -f "$file" "$partition/events.csv"

/opt/hive/bin/beeline \
    -u 'jdbc:hive2://127.0.0.1:10000/default' \
    -n team \
    -e "ALTER TABLE hw3.events ADD IF NOT EXISTS PARTITION (event_date='$day') LOCATION '$partition';"
