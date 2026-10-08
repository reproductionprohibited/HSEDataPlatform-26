#!/usr/bin/env bash

set -euo pipefail

TIMEOUT=120
INTERVAL=5
EXPECTED_NODES=3
SECONDARY_HOST="10.15.0.10"

export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export PATH="$HADOOP_HOME/bin:$PATH"

check_namenode() {
    hdfs dfsadmin -safemode get > /dev/null 2>&1
}

check_datanodes() {
    local report

    report=$(hdfs dfsadmin -report 2>/dev/null) || return 1

    live_nodes=$(sed -nE 's/^Live datanodes \(([0-9]+)\):.*/\1/p' <<< "$report")
    dead_nodes=$(sed -nE 's/^Dead datanodes \(([0-9]+)\):.*/\1/p' <<< "$report")

    [[ "$live_nodes" =~ ^[0-9]+$ ]] || return 1
    [[ "$dead_nodes" =~ ^[0-9]+$ ]] || return 1

    [[ "$live_nodes" -eq "$EXPECTED_NODES" && "$dead_nodes" -eq 0 ]]
}

check_secondary() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "hadoop@$SECONDARY_HOST" \
        'jps | grep -qE "^[0-9]+ SecondaryNameNode$"' \
        > /dev/null 2>&1
}

echo "Checking HDFS..."
echo

deadline=$((SECONDS + TIMEOUT))

while true; do
    namenode_ready=false
    datanodes_ready=false
    secondary_ready=false

    if check_namenode; then
        namenode_ready=true
    fi

    if check_datanodes; then
        datanodes_ready=true
    fi

    if check_secondary; then
        secondary_ready=true
    fi

    if [[ "$namenode_ready" == true &&
          "$datanodes_ready" == true &&
          "$secondary_ready" == true ]]; then
        echo "NameNode: available"
        echo "Secondary NameNode: available"
        echo "DataNodes: $live_nodes/$EXPECTED_NODES"
        echo "Dead DataNodes: $dead_nodes"
        echo
        echo "Cluster healthy"
        exit 0
    fi

    if (( SECONDS >= deadline )); then
        break
    fi

    sleep "$INTERVAL"
done

echo "NameNode: $([[ "$namenode_ready" == true ]] && echo available || echo unavailable)"
echo "Secondary NameNode: $([[ "$secondary_ready" == true ]] && echo available || echo unavailable)"
echo "DataNodes: ${live_nodes:-unknown}/$EXPECTED_NODES"
echo "Dead DataNodes: ${dead_nodes:-unknown}"
echo
echo "Cluster unhealthy (timeout: ${TIMEOUT}s)"

exit 1