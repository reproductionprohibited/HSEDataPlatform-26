#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ ! -d "$SPARK_HOME" ]]; then
    echo "Сначала установите Spark по инструкции ДЗ 4." >&2
    exit 1
fi

python_bin=${PYTHON_BIN:-python3}
"$python_bin" -c 'import sys; assert sys.version_info >= (3, 11), "Нужен Python 3.11+"'
"$python_bin" -m venv "$PROJECT_DIR/.venv"
"$PROJECT_DIR/.venv/bin/python" -m pip install -r "$PROJECT_DIR/requirements.txt"
cp "$PROJECT_DIR/conf/hive-site.xml" "$PROJECT_DIR/conf/spark-defaults.conf" "$SPARK_HOME/conf/"
"$PROJECT_DIR/.venv/bin/prefect" version
