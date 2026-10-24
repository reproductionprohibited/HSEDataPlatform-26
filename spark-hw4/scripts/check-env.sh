#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require hadoop team-15-nn

# До запуска должны работать HDFS, YARN и Metastore с HiveServer2 (ДЗ 1–3).
nc -zv team-15-en 9083

# Ожидается база hw3 и четыре строки.
spark-sql -e "SHOW DATABASES; SELECT * FROM hw3.events;"
