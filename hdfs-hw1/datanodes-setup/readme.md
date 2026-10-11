# Настройка и запуск HDFS-кластера

## Топология

| Сервер | Хост | Назначение | Демоны HDFS |
|---|---|---|---|
| — | `edge` (`team-15-en`) | Управляющий/jump-хост | — (отсюда запускаются скрипты Hadoop) |
| Server 1 | `team-15-nn` | Master | NameNode + DataNode |
| Server 2 | `team-15-00` | Вспомогательный | SecondaryNameNode + DataNode |
| Server 3 | `team-15-01` | Worker | DataNode |

Итого в кластере 3 DataNode (по одной на каждом сервере), что совпадает с `dfs.replication=3`: каждая реплика блока лежит на отдельном сервере.

Откуда берётся каждая роль:

| Роль | Где задаётся |
|---|---|
| NameNode на `team-15-nn` | `fs.defaultFS` в `core-site.xml` |
| SecondaryNameNode на `team-15-00` | `dfs.namenode.secondary.http-address` в `hdfs-site.xml` |
| DataNode на всех трёх серверах | файл `workers` на `edge` |

Предполагается, что Hadoop уже установлен на всех узлах, NameNode на `team-15-nn` уже настроен (и отформатирован), пользователь `hadoop` существует, а с `edge` можно подключаться по SSH к `team-15-*` хостам и выполнять там `sudo -iu hadoop`.

`start-dfs.sh` запускается от `hadoop` и сам заходит на узлы по SSH, поэтому у `hadoop` на `edge` должен быть беспарольный SSH-доступ ко всем трём `team-15-*` хостам.

## 1. Запустить скрипт настройки конфигурации

Скопируй `hdfs-config-sessions.sh` на `edge` и запусти его от обычного пользователя, у которого есть SSH-доступ к узлам:

```bash
chmod +x hdfs-config-sessions.sh
./hdfs-config-sessions.sh
```

Если Hadoop установлен не в `/opt/hadoop`, укажи правильный путь:

```bash
HADOOP_HOME=/путь/к/hadoop ./hdfs-config-sessions.sh
```

Скрипт автоматически записывает `core-site.xml` и `hdfs-site.xml` от имени пользователя `hadoop`:

- сначала на `edge` (там же записывается файл `workers`, см. шаг 2);
- затем на `team-15-00` (Server 2);
- затем на `team-15-01` (Server 3).

На всех узлах, куда пишет скрипт, конфиги одинаковые: каждый демон сам понимает свою роль по адресам в конфигах.

`team-15-nn` (Server 1) скрипт **не трогает**: NameNode к этому моменту уже настроен, а скрипт перезаписывает `core-site.xml` и `hdfs-site.xml` целиком и стёр бы свойства NameNode (например, `dfs.namenode.name.dir`). DataNode на `team-15-nn` берёт адрес NameNode из уже существующего там `fs.defaultFS`, поэтому дополнительная настройка ему не нужна.

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
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>team-15-00:9868</value>
    </property>
</configuration>
```

- `fs.defaultFS` задаёт адрес NameNode (Server 1).
- `dfs.replication=3` задаёт целевое количество реплик блоков; это значение само по себе не запускает DataNode.
- `dfs.namenode.secondary.http-address` указывает, где поднимать SecondaryNameNode. `start-dfs.sh` берёт хост отсюда, поэтому SNN запускается на `team-15-00` (Server 2), а не рядом с NameNode. Без этого свойства (значение по умолчанию `0.0.0.0:9868`) SNN стартует на хосте, где запущен `start-dfs.sh`, — у нас это `edge`.

## 2. Файл `workers` на `edge`

Скрипт настройки перезаписывает `$HADOOP_HOME/etc/hadoop/workers` на `edge` (от имени `hadoop`) списком из массива `WORKERS` и сразу выводит получившийся файл:

```text
team-15-nn
team-15-00
team-15-01
```

Каждая строка — это один DataNode: Server 1, Server 2 и Server 3 соответственно.

Файл `workers` используется скриптом `start-dfs.sh` для определения узлов, на которых нужно запускать DataNode. Поэтому он нужен только на `edge`, откуда запускается `start-dfs.sh`; на остальные узлы скрипт его не пишет.

Чтобы изменить набор DataNode, поправь массив `WORKERS` в `hdfs-config-sessions.sh` и перезапусти скрипт.

## 3. Запустить HDFS

Запускай с `edge` от пользователя `hadoop`:

```bash
sudo -iu hadoop
"$HADOOP_HOME/sbin/start-dfs.sh"
```

Скрипт запускает демоны HDFS, подключаясь к узлам по SSH:

1. NameNode на `team-15-nn` (из `fs.defaultFS`);
2. DataNode на каждом хосте из `workers` (`team-15-nn`, `team-15-00`, `team-15-01`);
3. SecondaryNameNode на `team-15-00` (из `dfs.namenode.secondary.http-address`).

Если какой-то демон уже работает (например, NameNode), `start-dfs.sh` выведет `… is running as process …` и пойдёт дальше; это не ошибка.

Проверить, куда будет поставлен SNN, можно заранее:

```bash
"$HADOOP_HOME/bin/hdfs" getconf -secondaryNameNodes
# team-15-00
```

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

| Сервер | Хост | Ожидаемые процессы `jps` |
|---|---|---|
| Server 1 (Master) | `team-15-nn` | `NameNode`, `DataNode` |
| Server 2 (Вспомогательный) | `team-15-00` | `SecondaryNameNode`, `DataNode` |
| Server 3 (Worker) | `team-15-01` | `DataNode` |

Если раньше SecondaryNameNode уже запускался в другом месте — на `team-15-nn` или на `edge` (так бывает, если `start-dfs.sh` запускали без `dfs.namenode.secondary.http-address`), — проверь `jps` на обоих хостах и останови лишний процесс вручную: `stop-dfs.sh` с новым конфигом будет искать SNN уже на `team-15-00`, и старый процесс останется висеть.

```bash
# на хосте со старым SNN (team-15-nn или edge) от пользователя hadoop
"$HADOOP_HOME/bin/hdfs" --daemon stop secondarynamenode
```

## Важные замечания

- **Не форматируй NameNode повторно.** Первичное форматирование выполняется один раз на `team-15-nn` при создании нового хранилища NameNode. В этой инструкции форматирование не требуется.
- Конфигурационные файлы должны указывать на `team-15-nn`, а не на `localhost`: на каждом сервере `localhost` означает именно этот сервер.
- Если скрипт сообщает, что каталог конфигурации не найден, проверь значение `HADOOP_HOME` и наличие `$HADOOP_HOME/etc/hadoop` на всех узлах.
- Если `dfsadmin -report` не показывает три живых DataNode, проверь SSH-доступ `hadoop` с `edge`, файл `workers` на `edge`, `jps`, конфиги и логи DataNode в `$HADOOP_HOME/logs/` на соответствующих серверах.
- Веб-интерфейс NameNode в Hadoop 3 обычно доступен по адресу `http://team-15-nn:9870`, SecondaryNameNode — `http://team-15-00:9868`. Если браузер доступен только с локальной машины или `edge`, может понадобиться SSH-туннель.
