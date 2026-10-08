#!/usr/bin/env bash

set -euo pipefail

export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"

TEST_DIR="/tmp/hdfs-smoke-$(date +%s)-$$"
LOCAL_DIR=$(mktemp -d)

cleanup() {
    hdfs dfs -rm -r -f "$TEST_DIR" > /dev/null 2>&1 || true
    rm -rf "$LOCAL_DIR"
}

trap cleanup EXIT

echo "Testing HDFS..."
echo

echo "HDFS smoke test" > "$LOCAL_DIR/input.txt"

hdfs dfs -mkdir -p "$TEST_DIR"
hdfs dfs -D dfs.replication=3 -put "$LOCAL_DIR/input.txt" "$TEST_DIR/test.txt"

echo "Write: OK"

hdfs dfs -get "$TEST_DIR/test.txt" "$LOCAL_DIR/output.txt"

if ! cmp -s "$LOCAL_DIR/input.txt" "$LOCAL_DIR/output.txt"; then
    echo "Read: FAILED"
    exit 1
fi

echo "Read: OK"

fsck_output=$(hdfs fsck "$TEST_DIR/test.txt" -files -blocks -locations)

if ! grep -q "Status: HEALTHY" <<< "$fsck_output"; then
    echo "Health: FAILED"
    exit 1
fi

echo "Health: OK"

if ! grep -Eq 'Live_repl=3([^0-9]|$)' <<< "$fsck_output"; then
    echo "Replication: FAILED"
    exit 1
fi

echo "Replication: 3/3"

echo
echo "Smoke test passed"