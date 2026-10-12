#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

for file in mapred-site.xml yarn-site.xml; do
  test -r "$PROJECT_DIR/conf/$file"
done
# Перед заменой конфигов проверяем все узлы.
for node in team-15-en "${NODES[@]}"; do
  processes=$(run_on_node "$node" 'sudo -n -iu hadoop jps -l')
  if grep -qE '[[:space:]]org\.apache\.hadoop\.(yarn\.server\.(resourcemanager\.ResourceManager|nodemanager\.NodeManager)|mapreduce\.v2\.hs\.JobHistoryServer)$' <<< "$processes"; then
    echo "$node: сначала остановите YARN и HistoryServer." >&2
    exit 1
  fi
done
MAPRED_B64=$(base64 < "$PROJECT_DIR/conf/mapred-site.xml" | tr -d '\n')
YARN_B64=$(base64 < "$PROJECT_DIR/conf/yarn-site.xml" | tr -d '\n')
for node in team-15-en "${NODES[@]}"; do
  {
    printf 'MAPRED_B64=%s\nYARN_B64=%s\n' "$MAPRED_B64" "$YARN_B64"
    cat <<'REMOTE'
set -euo pipefail
CONF_DIR=/opt/hadoop/etc/hadoop
test -d "$CONF_DIR"
backup=$(mktemp -d "$CONF_DIR/yarn-backup.XXXXXX")
for file in mapred-site.xml yarn-site.xml; do
  if [[ -f "$CONF_DIR/$file" ]]; then
    cp -p "$CONF_DIR/$file" "$backup/$file"
  fi
done
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
printf '%s' "$MAPRED_B64" | base64 -d > "$staging/mapred-site.xml"
printf '%s' "$YARN_B64" | base64 -d > "$staging/yarn-site.xml"
install -o hadoop -g hadoop -m 0644 "$staging/mapred-site.xml" "$staging/yarn-site.xml" "$CONF_DIR/"
echo "$(hostname -s): конфиги установлены, резервная копия $backup"
REMOTE
  } | run_on_node "$node" 'sudo -n bash -s'
done
