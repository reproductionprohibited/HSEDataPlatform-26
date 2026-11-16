#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ ! -x "$PROJECT_DIR/.venv/bin/python" ]]; then
    echo "Сначала запустите bash scripts/install-prefect.sh." >&2
    exit 1
fi

"$PROJECT_DIR/.venv/bin/python" "$PROJECT_DIR/flow.py"
