# Настройка NameNode и Secondary NameNode

NameNode запускается на `team-15-nn`, Secondary NameNode — на `team-15-en`.
Перед настройкой на обоих узлах должны быть установлены Java 17 и Hadoop 3.5.0 в `/opt/hadoop`, создан пользователь `hadoop` и настроены имена узлов.

## 1. Конфигурация

В `core-site.xml` указан адрес NameNode: `hdfs://team-15-nn:9000`.
В `hdfs-site.xml` заданы репликация 3 и адрес Secondary NameNode: `team-15-en:9868`.
Каталоги данных и остальные порты используются стандартные для Hadoop.

Скопировать папки `conf` и `scripts` из `hdfs-hw1` в `/home/team/hdfs-hw1` на NameNode и edge. При первой настройке сервисы должны быть остановлены.
На каждом из двух узлов под `team`:

```bash
cd /home/team/hdfs-hw1
bash scripts/configure-metadata.sh
sudo mkdir -p /home/hadoop/hdfs-hw1
sudo cp -R /home/team/hdfs-hw1/. /home/hadoop/hdfs-hw1/
sudo chown -R hadoop:hadoop /home/hadoop/hdfs-hw1
```

## 2. Запуск NameNode

На `team-15-nn` перейти к пользователю `hadoop`:

```bash
sudo -iu hadoop
```

Затем выполнить:

```bash
cd /home/hadoop/hdfs-hw1
bash scripts/init-namenode.sh --new-cluster
bash scripts/start-namenode.sh
jps
```

Форматирование выполняется только для нового пустого хранилища. Если метаданные уже существуют, скрипт пропускает этот шаг.
В выводе `jps` должен появиться `NameNode`.

## 3. Запуск Secondary NameNode

На `team-15-en` перейти к `hadoop` через `sudo -iu hadoop`, затем выполнить:

```bash
cd /home/hadoop/hdfs-hw1
bash scripts/start-secondary.sh
jps
```

В выводе должен появиться `SecondaryNameNode`.

## 4. Проверка кластера

После запуска трех DataNode на `team-15-nn`, `team-15-00`, `team-15-01` проверить отчет с edge под `hadoop`:

```bash
hdfs dfsadmin -report
```

В отчете должны быть три живые DataNode в состоянии Normal, без мертвых узлов.

Для просмотра UI выполнить на локальном компьютере:

```bash
ssh -N -L 9870:10.15.0.11:9870 team@111.88.130.160
```

Открыть `http://localhost:9870`, вкладку Datanodes. Должны отображаться три исправные DataNode. [Скриншот проверки](../evidence/datanodes.png).

## 5. Остановка

Под `hadoop` сначала на edge, затем на NameNode:

```bash
bash /home/hadoop/hdfs-hw1/scripts/stop-metadata.sh
```

Для повторного запуска использовать `start-namenode.sh` на NameNode и `start-secondary.sh` на edge. Форматировать NameNode повторно не нужно.
