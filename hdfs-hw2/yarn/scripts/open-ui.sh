#!/usr/bin/env bash
set -euo pipefail
# Запускать на своем компьютере. Завершение туннеля: Ctrl+C.
echo "ResourceManager: http://localhost:8088"
echo "HistoryServer: http://localhost:19888"
echo "NodeManager nn/00/01: http://localhost:8042 / :8043 / :8044"
echo "NameNode: http://localhost:9870; Secondary: http://localhost:9868"
echo "DataNode nn/00/01: http://localhost:9864 / :9865 / :9866"
exec ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 \
  -L 127.0.0.1:8088:10.15.0.11:8088 \
  -L 127.0.0.1:19888:10.15.0.11:19888 \
  -L 127.0.0.1:8042:10.15.0.11:8042 \
  -L 127.0.0.1:8043:10.15.0.12:8042 \
  -L 127.0.0.1:8044:10.15.0.13:8042 \
  -L 127.0.0.1:9870:10.15.0.11:9870 \
  -L 127.0.0.1:9868:10.15.0.13:9868 \
  -L 127.0.0.1:9864:10.15.0.11:9864 \
  -L 127.0.0.1:9865:10.15.0.12:9864 \
  -L 127.0.0.1:9866:10.15.0.13:9864 \
  team@111.88.130.160
