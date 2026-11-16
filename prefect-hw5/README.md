# ДЗ 5. Поток Prefect для обработки данных в Spark

## Состав

- `flow.py` — поток Prefect: проверка исходных данных и YARN, запуск Spark, проверка результата.
- `job.py` — чтение CSV из HDFS, очистка, агрегация и запись таблицы.
- `conf/` — адрес Hive Metastore и параметры Spark on YARN.
- `scripts/install-prefect.sh` — установка Prefect в отдельное окружение и копирование конфигурации Spark.
- `scripts/run-flow.sh` — запуск потока.

Исходные данные — CSV из ДЗ 3 в `/user/team/hw3/events/event_date=YYYY-MM-DD/events.csv`.
Результат — таблица `hw5.events_daily` в Hive Metastore, файлы Parquet в
`/user/hive/warehouse/hw5.db/events_daily`.

## Подготовка

Должны работать HDFS, YARN и Hive Metastore из ДЗ 1–4. Spark 3.5.9
установлен на `team-15-nn` под пользователем `hadoop` по инструкции
[ДЗ 4](../spark-hw4/README.md). На узле необходим Python 3.11 или новее
с модулем `venv`.

Скопировать каталог `prefect-hw5` на `team-15-nn`, войти под `hadoop`
и перейти в этот каталог. Если Python 3.11+ доступен под именем,
отличным от `python3`, передать путь через `PYTHON_BIN`.

## Запуск скриптами

```bash
bash scripts/install-prefect.sh
bash scripts/run-flow.sh
```

`install-prefect.sh` создаёт `.venv`, устанавливает Prefect 3 и копирует
`hive-site.xml` и `spark-defaults.conf` в `$SPARK_HOME/conf`.
`run-flow.sh` запускает поток. Повторный запуск перезаписывает таблицу
`hw5.events_daily`.

При отсутствии Python 3.11+ сначала установить его на `team-15-nn`,
затем выполнить, например:

```bash
PYTHON_BIN=python3.11 bash scripts/install-prefect.sh
```

## Шаги потока

| № | Задача Prefect | Действие |
|---|---|---|
| 1 | Проверка данных в HDFS | Проверяет каталог с CSV и выводит список файлов через `hdfs dfs`. |
| 2 | Проверка YARN | Проверяет связь с кластером командой `yarn node -list`. |
| 3 | Обработка данных в Spark | Запускает `job.py` через `spark-submit --master yarn --deploy-mode client`. |
| 4 | Проверка итоговой таблицы | Проверяет каталог в HDFS и читает партиции и строки через `spark-sql`. |

В `job.py` Spark создаёт сессию с `master=yarn` и поддержкой Hive.
Конфигурацию HDFS Spark берёт из `HADOOP_CONF_DIR`. Скрипт читает CSV
по адресу `hdfs://team-15-nn:9000/user/team/hw3/events` и извлекает `event_date`
из имён каталогов партиций, приводит `event_id` и `user_id` к `int`,
`event_date` к `date`, нормализует `event_type` и удаляет некорректные
строки. Затем считает число событий и уникальных пользователей по дню
и типу события и сохраняет результат как партиционированную таблицу
Parquet `hw5.events_daily`.

## Проверка результата

Успешный запуск завершается состоянием `Completed` для потока Prefect.
В YARN UI (порт 8088 на `team-15-nn`) должно появиться приложение
`hw5-team15` со статусом `SUCCEEDED`. Команды для проверки вручную:

```bash
hdfs dfs -ls -R /user/hive/warehouse/hw5.db/events_daily
spark-sql -e 'SHOW PARTITIONS hw5.events_daily; SELECT * FROM hw5.events_daily;'
```

На исходных CSV из ДЗ 3 ожидаются две партиции: `2026-10-20` и
`2026-10-21`. Для каждого дня и типа события выводится число событий
и число уникальных пользователей. Если команда `spark-submit` или
проверка завершится с ошибкой, задача Prefect и весь поток получат
состояние `Failed`.
