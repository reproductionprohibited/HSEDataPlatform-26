#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require hadoop team-15-nn

spark-submit "$PROJECT_DIR/job.py"
