#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Нужен sudo."
  exit 1
fi

apt-get update
apt-get install -y openjdk-17-jdk-headless ca-certificates curl tar

JAVA_HOME="/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)"

echo "Узел: $(hostname)"
echo "JAVA_HOME=$JAVA_HOME"
"$JAVA_HOME/bin/java" -version
"$JAVA_HOME/bin/javac" -version
test -x "$JAVA_HOME/bin/jps"

echo "Java 17 и необходимые инструменты установлены."
