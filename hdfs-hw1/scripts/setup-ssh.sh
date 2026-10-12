#!/usr/bin/env bash
set -euo pipefail

# Запускаем на edge под team.
# Создаем ключ при необходимости и настраиваем доступ к четырем узлам.

PUBLIC_KEY="/home/hadoop/.ssh/id_ed25519.pub"
ADMIN_KEY="$HOME/.ssh/team_internal"
NODES=(team-15-nn team-15-00 team-15-01)

if [[ "$(whoami)" != "team" ]]; then
    echo "Запустите скрипт под пользователем team."
    exit 1
fi

if [[ "$(hostname -s)" != "team-15-en" ]]; then
    echo "Запустите скрипт на edge-ноде team-15-en."
    exit 1
fi

if [[ ! -r "$ADMIN_KEY" ]]; then
    echo "Недоступен административный SSH-ключ: $ADMIN_KEY"
    exit 1
fi

if ! id hadoop >/dev/null 2>&1; then
    echo "Сначала создайте пользователя hadoop."
    exit 1
fi

echo "Подготавливаем SSH пользователя hadoop на edge..."

sudo -n -u hadoop -H bash <<'HADOOP'
set -euo pipefail

ssh_dir="$HOME/.ssh"
private_key="$ssh_dir/id_ed25519"
public_key_file="$private_key.pub"
authorized_keys="$ssh_dir/authorized_keys"

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

if [[ -e "$private_key" ]]; then
    if [[ ! -s "$private_key" || ! -s "$public_key_file" ]]; then
        echo "Неполная пара ключей. Требуется проверка вручную."
        exit 1
    fi

    echo "Существующую пару ключей сохраняем."
else
    if [[ -e "$public_key_file" ]]; then
        echo "Есть публичный ключ без приватного. Не перезаписываем."
        exit 1
    fi

    ssh-keygen -q \
        -t ed25519 \
        -N "" \
        -C "hadoop@team-15-en" \
        -f "$private_key"

    echo "Создана новая пара ключей."
fi

chmod 600 "$private_key"
chmod 644 "$public_key_file"

touch "$authorized_keys"
chmod 600 "$authorized_keys"

public_key="$(cat "$public_key_file")"

if ! grep -qxF -- "$public_key" "$authorized_keys"; then
    printf "%s\n" "$public_key" >> "$authorized_keys"
fi

echo "Публичный ключ разрешен на edge."
HADOOP

for node in "${NODES[@]}"; do
    echo "Добавляем ключ на $node..."

    sudo -n cat "$PUBLIC_KEY" |
        ssh -i "$ADMIN_KEY" \
            -o IdentitiesOnly=yes \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=yes \
            -o ConnectTimeout=10 \
            "team@$node" '
                set -eu

                public_key=$(cat)
                test -n "$public_key"

                # Проверяем пользователя до изменения файлов.
                id hadoop >/dev/null

                ssh_dir="/home/hadoop/.ssh"
                authorized_keys="$ssh_dir/authorized_keys"

                sudo -n install -d \
                    -m 700 -o hadoop -g hadoop "$ssh_dir"

                sudo -n touch "$authorized_keys"

                # Сохраняем существующие записи и не добавляем дубликат.
                if ! sudo -n grep -qxF -- "$public_key" "$authorized_keys"; then
                    printf "%s\n" "$public_key" |
                        sudo -n tee -a "$authorized_keys" >/dev/null
                fi

                sudo -n chown hadoop:hadoop "$authorized_keys"
                sudo -n chmod 600 "$authorized_keys"
            '

    echo "$node: готово"
done

echo "Публичный ключ установлен на всех четырех узлах."
