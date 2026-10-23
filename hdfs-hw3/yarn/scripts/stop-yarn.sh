#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

run_on_node team-15-nn 'sudo -n -iu hadoop /opt/hadoop/bin/mapred --daemon stop historyserver'
for node in "${NODES[@]}"; do
  run_on_node "$node" 'sudo -n -iu hadoop /opt/hadoop/bin/yarn --daemon stop nodemanager'
done
run_on_node team-15-nn 'sudo -n -iu hadoop /opt/hadoop/bin/yarn --daemon stop resourcemanager'
# Проверяем, что процессы завершились.
for node in "${NODES[@]}"; do
  processes=$(run_on_node "$node" 'sudo -n -iu hadoop jps -l')
  if grep -qE '[[:space:]]org\.apache\.hadoop\.(yarn\.server\.(resourcemanager\.ResourceManager|nodemanager\.NodeManager)|mapreduce\.v2\.hs\.JobHistoryServer)$' <<< "$processes"; then
    echo "$node: процесс YARN или HistoryServer еще работает." >&2
    exit 1
  fi
done
echo "YARN и HistoryServer остановлены."
