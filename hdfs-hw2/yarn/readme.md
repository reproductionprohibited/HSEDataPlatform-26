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

Вызвать `yarn node -list` на `team-15-nn`. Должно быть `TotalNodes: 3` и список из трех нод, на трех серверах - nn/01/00

## UI

На локальной машине создать `ssh` туннель до `ResourceManager` и `JobHistory`:

`ssh -L 8088:team-15-nn:8088 -L 9870:team-15-nn:9870 -L 19888:team-15-nn:19888 user@edge`