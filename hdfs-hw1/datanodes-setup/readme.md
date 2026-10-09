# Настройка и запуск HDFS-кластера

## Топология

| Сервер | Роль |
|---|---|
| `edge` (`team-15-en`) | Управляющий/jump-хост; с него запускаются скрипты Hadoop |
| `team-15-nn` | NameNode + SecondaryNameNode + DataNode №1 |
| `team-15-00` | DataNode №2 |
| `team-15-01` | DataNode №3 |

Предполагается, что Hadoop уже установлен на всех узлах, пользователь `hadoop` существует, а с `edge` можно подключаться по SSH к трём `team-15-*` хостам и выполнять `sudo -iu hadoop`.

## 1. Запустить скрипт настройки конфигурации

Скопируй `hdfs-config-sessions.sh` на `edge` и запусти его от обычного пользователя, у которого есть SSH-доступ к узлам:

```bash
chmod +x hdfs-config-sessions.sh
./hdfs-config-sessions.sh
```

Если Hadoop установлен не в `/home/hadoop/hadoop`, укажи правильный путь:

```bash
HADOOP_HOME=/путь/к/hadoop ./hdfs-config-sessions.sh
```

Скрипт автоматически записывает `core-site.xml` и `hdfs-site.xml` от имени пользователя `hadoop`:

- сначала на `edge`;
- затем на `team-15-00`;
- затем на `team-15-01`.

После записи конфигов на каждом удалённом сервере скрипт открывает интерактивную shell-сессию пользователя `hadoop`. При необходимости можно выполнить дополнительные команды. Нажми **Ctrl+D**, чтобы выйти из shell и вернуться по SSH на `edge`; скрипт продолжит работу со следующим узлом.

### Какие конфиги записывает скрипт

Файл `$HADOOP_HOME/etc/hadoop/core-site.xml`:

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://team-15-nn:9000</value>
    </property>
</configuration>
```

Файл `$HADOOP_HOME/etc/hadoop/hdfs-site.xml`:

```xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
```

`fs.defaultFS` задаёт адрес NameNode. `dfs.replication=3` задаёт целевое количество реплик блоков; это значение само по себе не запускает DataNode.

## 2. Проверить файл `workers` на `edge`

Скрипт настройки не изменяет `workers`. На `edge` от имени `hadoop` проверь файл `$HADOOP_HOME/etc/hadoop/workers`:

```text
team-15-nn
team-15-00
team-15-01
```

Например, отредактировать его можно так:

```bash
sudo -iu hadoop
vim "$HADOOP_HOME/etc/hadoop/workers"
```

Файл `workers` используется скриптом `start-dfs.sh` для определения узлов, на которых нужно запускать DataNode. Убедись, что в нём не осталось старых имён вроде `namenode`, `datanode1` или `datanode2`.

## 3. Запустить HDFS

Запускай с `edge` от пользователя `hadoop`:

```bash
sudo -iu hadoop
"$HADOOP_HOME/sbin/start-dfs.sh"
```

Скрипт запускает демоны HDFS, подключаясь к удалённым узлам по SSH.

## 4. Проверить состояние кластера

На `edge`, от имени `hadoop`:

```bash
"$HADOOP_HOME/bin/hdfs" dfsadmin -report
```

Ожидаемый результат:

```text
Live datanodes (3):
```

Можно проверить процессы командой `jps` на каждом узле:

- `team-15-nn`: ожидаются `NameNode`, `SecondaryNameNode` и `DataNode`;
- `team-15-00`: ожидается `DataNode`;
- `team-15-01`: ожидается `DataNode`.

## Важные замечания

- **Не форматируй NameNode повторно.** Первичное форматирование выполняется один раз на `team-15-nn` при создании нового хранилища NameNode. В этой инструкции форматирование не требуется.
- Конфигурационные файлы должны указывать на `team-15-nn`, а не на `localhost`: на каждом сервере `localhost` означает именно этот сервер.
- Если скрипт сообщает, что каталог конфигурации не найден, проверь значение `HADOOP_HOME` и наличие `$HADOOP_HOME/etc/hadoop` на всех узлах.
- Если `dfsadmin -report` не показывает три живых DataNode, проверь SSH-доступ, файл `workers` на `edge`, конфиги и логи Hadoop на соответствующих серверах.
- Веб-интерфейс NameNode в Hadoop 3 обычно доступен по адресу `http://team-15-nn:9870`. Если браузер доступен только с локальной машины или `edge`, может понадобиться SSH-туннель.
