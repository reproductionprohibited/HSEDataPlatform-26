#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y postgresql libpostgresql-jdbc-java curl python3
sudo systemctl enable --now postgresql

version=4.0.0-alpha-2
archive="apache-hive-$version-bin.tar.gz"
url="https://archive.apache.org/dist/hive/hive-$version"
target="/opt/apache-hive-$version-bin"

mkdir -p "$HOME/hive-install"
cd "$HOME/hive-install"

if [[ ! -d "$target" ]]; then
    curl -fLO --retry 3 "$url/$archive.sha256"
    if ! sha256sum -c "$archive.sha256"; then
        curl -fLO --retry 3 -C - "$url/$archive"
        sha256sum -c "$archive.sha256"
    fi
    sudo tar -xzf "$archive" -C /opt
fi

if [[ ! -e /opt/hive ]]; then
    sudo ln -s "$target" /opt/hive
fi

sudo cp /usr/share/java/postgresql.jar /opt/hive/lib/
sudo chown "$(id -un):$(id -gn)" /opt/hive/conf

echo "Hive и PostgreSQL установлены."
