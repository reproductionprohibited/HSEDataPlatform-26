#!/usr/bin/env bash
set -uo pipefail

if [[ "$(whoami)" != "hadoop" ]]; then
  echo "Запускать надо под пользователем hadoop."
  exit 1
fi

if [[ "$(hostname)" != "team-15-en" ]]; then
  echo "Запускать надо на edge-ноде team-15-en."
  exit 1
fi

failed=0

for node in team-15-en team-15-nn team-15-00 team-15-01; do
  echo "===== $node ====="

  if ssh -n \
    -i "$HOME/.ssh/id_ed25519" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 \
    "hadoop@$node" \
    'bash -lc "
      set -e

      echo Пользователь:
      whoami

      echo Узел:
      hostname

      echo JAVA_HOME / HADOOP_HOME / HADOOP_CONF_DIR:
      printenv JAVA_HOME HADOOP_HOME HADOOP_CONF_DIR

      echo Пути команд:
      command -v java
      command -v hadoop
      command -v hdfs

      echo Версия Java:
      java -version

      echo Версия Hadoop:
      hadoop version
    "'
  then
    echo "$node: команды проверки выполнены успешно."
  else
    echo "$node: ошибка проверки."
    failed=1
  fi

  echo
done

if [[ "$failed" -eq 0 ]]; then
  echo "Проверки выполнены на всех четырех узлах."
  echo "Ожидаемые версии в выводе: Java 17 и Hadoop 3.5.0."
else
  echo "На некоторых узлах обнаружены ошибки."
fi

exit "$failed"
