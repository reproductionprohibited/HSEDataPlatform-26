#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require team team-15-en

# Ожидаются 1 таблица, две партиции и 4 записи.
/opt/hive/bin/beeline -u 'jdbc:hive2://127.0.0.1:10000/default' -n team -e "
SHOW TABLES IN hw4;
SHOW PARTITIONS hw4.events_agg;
SELECT * FROM hw4.events_agg;
"
