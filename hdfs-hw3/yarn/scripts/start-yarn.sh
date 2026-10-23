#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

for node in "${NODES[@]}"; do
  {
    printf 'NODE=%s\n' "$node"
    cat <<'REMOTE'
set -euo pipefail
HADOOP_HOME=/opt/hadoop
start_daemon() {
  local bin="$1" daemon="$2" class="$3" processes
  processes=$(jps -l)
  if grep -qF " $class" <<< "$processes"; then
    echo "$daemon уже запущен."
    return
  fi
  "$HADOOP_HOME/bin/$bin" --daemon start "$daemon"
  for attempt in {1..15}; do
    processes=$(jps -l)
    if grep -qF " $class" <<< "$processes"; then
      echo "$daemon: процесс запущен."
      return
    fi
    sleep 2
  done
  echo "$daemon не запустился: проверьте /opt/hadoop/logs." >&2
  return 1
}
if [[ "$NODE" == team-15-nn ]]; then
  start_daemon yarn resourcemanager org.apache.hadoop.yarn.server.resourcemanager.ResourceManager
  start_daemon mapred historyserver org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer
fi
start_daemon yarn nodemanager org.apache.hadoop.yarn.server.nodemanager.NodeManager
REMOTE
  } | run_on_node "$node" 'sudo -n -iu hadoop bash -s'
done
# Дожидаемся регистрации трех NodeManager.
for attempt in {1..15}; do
  report=$(run_on_node team-15-nn 'sudo -n -iu hadoop /opt/hadoop/bin/yarn node -list')
  if grep -qE 'Total[[:space:]]+Nodes[[:space:]]*:[[:space:]]*3[[:space:]]*$' <<< "$report"; then
    printf '%s\n' "$report"
    exit 0
  fi
  sleep 2
done
printf '%s\n' "$report"
echo "Не зарегистрированы три RUNNING NodeManager. Проверьте логи." >&2
exit 1
