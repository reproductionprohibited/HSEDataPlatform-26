#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require hadoop team-15-nn

# Ожидаются папки event_date=2026-10-20 и event_date=2026-10-21 с parquet файлами.
hdfs dfs -ls -R /user/hive/warehouse/hw4.db/events_agg
