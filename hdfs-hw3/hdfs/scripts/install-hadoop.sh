#!/usr/bin/env bash
set -euo pipefail

VERSION="3.5.0"
DIST_DIR="/home/team/dist"
ARCHIVE="hadoop-$VERSION.tar.gz"
INSTALL_DIR="/opt/hadoop-$VERSION"
JAVA_HOME="/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)"

if [[ "$EUID" -ne 0 ]]; then
  echo "Запустите скрипт через sudo."
  exit 1
fi

if ! id hadoop >/dev/null 2>&1; then
  echo "Пользователь hadoop не создан."
  exit 1
fi

if [[ ! -x "$JAVA_HOME/bin/java" ]]; then
  echo "Java 17 не найдена: $JAVA_HOME"
  exit 1
fi

cd "$DIST_DIR"
sha512sum --check "$ARCHIVE.sha512"

# Распаковываем отдельно, чтобы сбой не оставил
# незавершенную установку в основном каталоге.
if [[ ! -e "$INSTALL_DIR" ]]; then
  STAGING_DIR="$(mktemp -d /opt/hadoop-install.XXXXXX)"
  tar --extract --gzip --no-same-owner \
    --file "$ARCHIVE" --directory "$STAGING_DIR"

  chown -R hadoop:hadoop "$STAGING_DIR/hadoop-$VERSION"
  mv "$STAGING_DIR/hadoop-$VERSION" "$INSTALL_DIR"
  rmdir "$STAGING_DIR"
else
  echo "Каталог $INSTALL_DIR уже существует, не перезаписываем."
fi

if [[ ! -x "$INSTALL_DIR/bin/hadoop" ]]; then
  echo "Не найден исполняемый файл Hadoop."
  exit 1
fi

# Не заменяем чужой каталог или ссылку на другую версию.
if [[ -e /opt/hadoop || -L /opt/hadoop ]]; then
  if [[ "$(readlink -f /opt/hadoop)" != "$INSTALL_DIR" ]]; then
    echo "/opt/hadoop уже занят другой установкой."
    exit 1
  fi
else
  ln -s "$INSTALL_DIR" /opt/hadoop
fi

# JAVA_HOME нужен Hadoop и при запуске без login-shell.
ENV_FILE="$INSTALL_DIR/etc/hadoop/hadoop-env.sh"

if ! grep -qxF "export JAVA_HOME=$JAVA_HOME" "$ENV_FILE"; then
  sed -i '/^[[:space:]]*export JAVA_HOME=/d' "$ENV_FILE"
  printf '\nexport JAVA_HOME=%s\n' "$JAVA_HOME" >> "$ENV_FILE"
fi

# Окружение для новых входов пользователей.
cat > /etc/profile.d/hadoop.sh <<EOF
export JAVA_HOME="$JAVA_HOME"
export HADOOP_HOME="/opt/hadoop"
export HADOOP_CONF_DIR="/opt/hadoop/etc/hadoop"
export PATH="\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH"
EOF

chmod 644 /etc/profile.d/hadoop.sh

echo "Проверяем Hadoop под пользователем hadoop..."
sudo -iu hadoop /opt/hadoop/bin/hadoop version

echo "Hadoop $VERSION установлен на $(hostname)."
