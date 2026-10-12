# ДЗ2. Yarn

## Конфигурация

Чтобы развернуть YARN `ResourceManager`, `NodeManager` и `HistoryServer`, надо на всех хостах от имени пользователя `hadoop` вставить 2 конфига:

1. `$HADOOP_HOME/etc/hadoop/mapred-site.xml`

```xml
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<property>
		<name>mapreduce.application.classpath</name>
		<value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
	</property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>team-15-nn:10020</value>
    </property>
</configuration>
```

2. `$HADOOP_HOME/etc/hadoop/yarn-site.xml`

```xml
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>team-15-nn</value>
    </property>
    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
    </property>
    <property>
            <name>yarn.nodemanager.env-whitelist</name>
            <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
```

## Скрипты

Нужны установленный Hadoop в `/opt/hadoop`, работающий HDFS и ключ `~/.ssh/team_internal` на edge.

На локальном компьютере из корня репозитория:

```bash
scp -r hdfs-hw2 team@111.88.130.160:/home/team/
ssh team@111.88.130.160
```

На edge под `team`, при остановленных YARN и HistoryServer:

```bash
cd /home/team/hdfs-hw2/yarn
bash scripts/configure-yarn.sh
bash scripts/start-yarn.sh
```

Конфиги из `conf/` устанавливаются на все узлы с резервной копией. Для повторного запуска достаточно `start-yarn.sh`. Остановка: `bash scripts/stop-yarn.sh`.

## Запуск

От имени пользователя `hadoop` на серверах:

1. team-15-nn:

`yarn --daemon start nodemanager`

`yarn --daemon start resourcemanager`

`mapred --daemon start historyserver`

Проверка: вызвать `jps`. Должен быть `NodeManager`, `ResourceManager`, `JobHistoryServer`

2. team-15-00

`yarn --daemon start nodemanager`

Проверка: вызвать `jps`. Должен быть `NodeManager`

3. team-15-01

`yarn --daemon start nodemanager`

Проверка: вызвать `jps`. Должен быть `NodeManager`

## Проверка Yarn

Вызвать `yarn node -list` на `team-15-nn`. Должно быть `Total Nodes:3` и список из трех нод, на трех серверах - nn/01/00

## UI

Для запуска скрипта нужны Bash и SSH (на Windows — Git Bash или WSL).

На локальном компьютере из корня репозитория:

```bash
bash hdfs-hw2/yarn/scripts/open-ui.sh
```

Адреса в браузере:

- ResourceManager: http://localhost:8088
- HistoryServer: http://localhost:19888
- NodeManager nn / 00 / 01: http://localhost:8042 / http://localhost:8043 / http://localhost:8044
- NameNode и Secondary: http://localhost:9870 / http://localhost:9868
- DataNode nn / 00 / 01: http://localhost:9864 / http://localhost:9865 / http://localhost:9866

Закрыть туннель: `Ctrl+C`.

Скриншоты: [кластер](evidence/cluster.png), [узлы](evidence/nodes.png), [HistoryServer](evidence/job_history.png).
