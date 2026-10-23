# Развёртывание HDFS-кластера

## Описание

В рамках домашнего задания разворачивается распределённый HDFS-кластер на базе Apache Hadoop 3.5.0.

Состав кластера:
- 1 NameNode;
- 1 Secondary NameNode;
- 3 DataNode.

## Инфраструктура

| Сервер | IP-адрес | Назначение |
|---|---|---|
| team-15-en | 10.15.0.10 | Edge, управляющий сервер |
| team-15-nn | 10.15.0.11 | NameNode, DataNode |
| team-15-00 | 10.15.0.12 | DataNode |
| team-15-01 | 10.15.0.13 | Secondary NameNode, DataNode |

## Требования

- Ubuntu Linux;
- Java 17;
- Apache Hadoop 3.5.0;
- SSH-доступ между серверами;
- пользователь `hadoop` для запуска сервисов.

Hadoop устанавливается в `/opt/hadoop`. Для подготовки выданных курсом серверов нужен пользователь `team` с sudo без пароля и ключ `~/.ssh/team_internal` на edge.

## Установка Java и Hadoop

На своем компьютере из корня репозитория скопировать файлы на edge:

```bash
scp -r hdfs-hw1 team@111.88.130.160:/home/team/
ssh team@111.88.130.160
```

На edge под `team` проверить доступ к внутренним узлам. При первом подключении сверить ключ сервера и сохранить его:

```bash
for node in team-15-nn team-15-00 team-15-01; do
  ssh -i ~/.ssh/team_internal team@$node hostname
done
```

Затем выполнить скрипты установки в следующем порядке:

```bash
cd /home/team/hdfs-hw1
bash scripts/apply-fix-to-hosts.sh
bash scripts/apply-users-to-hosts.sh
bash scripts/apply-java-to-hosts.sh
bash scripts/download-hadoop.sh
bash scripts/distribute-hadoop.sh
bash scripts/apply-hadoop-to-hosts.sh
bash scripts/setup-ssh.sh
```

Скрипты `apply-*` выполняют настройку на всех четырех узлах. Архив Hadoop проверяется по SHA-512. `setup-ssh.sh` настраивает доступ пользователя `hadoop` с edge к узлам кластера.

Для проверки скопировать файлы в домашний каталог `hadoop` на edge:

```bash
sudo mkdir -p /home/hadoop/hdfs-hw1
sudo cp -R /home/team/hdfs-hw1/. /home/hadoop/hdfs-hw1/
sudo chown -R hadoop:hadoop /home/hadoop/hdfs-hw1
sudo -iu hadoop bash /home/hadoop/hdfs-hw1/scripts/check-ssh.sh
sudo -iu hadoop bash /home/hadoop/hdfs-hw1/scripts/check-hadoop.sh
```

При первом SSH-подключении под `hadoop` также сохранить сверенные ключи серверов. В проверке установки ожидаются Java 17 и Hadoop 3.5.0.

## Развёртывание

Управление кластером осуществляется с edge-сервера `team-15-en`.

Подключение к серверу:

```bash
ssh team@111.88.130.160
```

Первоначальная настройка выполняется при остановленном HDFS:

1. Настроить и инициализировать NameNode на `team-15-nn` по [инструкции](docs/namenode.md), разделы 1–2. Существующий NameNode повторно не форматировать.
2. Настроить DataNode и файл `workers` на edge по [инструкции](datanodes-setup/readme.md), разделы 1–2. При открытии удалённых сессий нажимать Ctrl+D для продолжения скрипта.
3. Запустить кластер на edge под `hadoop`:

```bash
sudo -iu hadoop
/opt/hadoop/sbin/start-dfs.sh
/opt/hadoop/bin/hdfs dfsadmin -report
```

Ожидается `Live datanodes (3)` и отсутствие мертвых узлов. Secondary NameNode запускается на `team-15-01`.

Остановка кластера на edge под `hadoop`:

```bash
/opt/hadoop/sbin/stop-dfs.sh
```

Для повторного запуска выполнить `start-dfs.sh`.

## Веб-интерфейс NameNode

Для просмотра состояния кластера используется веб-интерфейс NameNode.

С локального компьютера можно настроить SSH-туннель через edge-сервер:

```bash
ssh -L 9870:10.15.0.11:9870 team@111.88.130.160
```

После подключения открыть в браузере:

http://localhost:9870

В интерфейсе можно проверить регистрацию трёх DataNode и состояние HDFS.

## Результаты проверки

В папке `evidence/` размещен скриншот веб-интерфейса с тремя работающими DataNode.
