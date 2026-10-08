#!/usr/bin/env bash

set -euo pipefail

export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"

TEST_DIR="/tmp/hdfs-persistence-${USER}"
TEST_FILE="$TEST_DIR/test.txt"
LOCAL_DIR="${TMPDIR:-/tmp}/hdfs-persistence-${USER}"
SOURCE_FILE="$LOCAL_DIR/source.txt"
RESULT_FILE="$LOCAL_DIR/result.txt"

prepare() {
    if [[ -e "$LOCAL_DIR" ]] || hdfs dfs -test -e "$TEST_DIR"; then
        echo "Test data already exists"
        exit 1
    fi

    mkdir "$LOCAL_DIR"
    printf "HDFS persistence test\n%s\n" "$(date -u)" > "$SOURCE_FILE"

    hdfs dfs -mkdir "$TEST_DIR"
    hdfs dfs -put "$SOURCE_FILE" "$TEST_FILE"

    echo "File uploaded"
    echo "Restart the cluster, then run: $0 verify"
}

verify() {
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo "Source file not found"
        exit 1
    fi

    if ! hdfs dfs -test -e "$TEST_FILE"; then
        echo "HDFS file not found"
        exit 1
    fi

    hdfs dfs -get -f "$TEST_FILE" "$RESULT_FILE"

    if ! cmp -s "$SOURCE_FILE" "$RESULT_FILE"; then
        echo "File mismatch"
        exit 1
    fi

    echo "Persistence test passed"
}

cleanup() {
    if [[ ! -f "$SOURCE_FILE" ]]; then
        echo "Test data not found"
        exit 1
    fi

    hdfs dfs -rm -f "$TEST_FILE"
    hdfs dfs -rmdir "$TEST_DIR"
    rm -f "$SOURCE_FILE" "$RESULT_FILE"
    rmdir "$LOCAL_DIR"

    echo "Test data removed"
}

case "${1:-}" in
    prepare)
        prepare
        ;;
    verify)
        verify
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 {prepare|verify|cleanup}"
        exit 1
        ;;
esac