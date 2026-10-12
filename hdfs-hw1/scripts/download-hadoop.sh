#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="/home/team/dist"

VERSION="3.5.0"
ARCHIVE="hadoop-$VERSION.tar.gz"
BASE_URL="https://downloads.apache.org/hadoop/common/hadoop-$VERSION"

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

echo "Скачиваем Hadoop $VERSION..."
curl --fail --location --retry 3 \
  --continue-at - \
  --output "$ARCHIVE.part" \
  "$BASE_URL/$ARCHIVE"

echo "Скачиваем контрольную сумму..."
curl --fail --location --retry 3 \
  --output "$ARCHIVE.sha512" \
  "$BASE_URL/$ARCHIVE.sha512"

mv "$ARCHIVE.part" "$ARCHIVE"

echo "Проверяем SHA-512..."
sha512sum --check "$ARCHIVE.sha512"

echo "Архив проверен: $DOWNLOAD_DIR/$ARCHIVE"
