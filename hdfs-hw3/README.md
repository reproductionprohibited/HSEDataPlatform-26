# ДЗ 3. Apache Hive

## Состав

- hdfs/ — HDFS из ДЗ 1.
- yarn/ — YARN из ДЗ 2.
- hive/ — скрипты Hive, SQL, данные и результаты проверок.

## Окружение и схема

Ubuntu 24.04, Java 17, Hadoop 3.5.0, Hive 4.0.0-alpha-2,
PostgreSQL 16.

Hive установлен на team-15-en и запускается пользователем team.
HDFS и YARN настраиваются по hdfs/README.md и yarn/readme.md.

Клиенты Beeline подключаются к HiveServer2 на 127.0.0.1:10000.
HiveServer2 обращается к отдельному Metastore на порту 9083.
Метаданные хранятся в PostgreSQL, данные таблицы — в HDFS.
Embedded Derby не используется.

## Установка

Скопировать каталог hive на team-15-en, перейти в него и выполнить:

    bash scripts/install-hive.sh
    bash scripts/configure-hive.sh
    bash scripts/start-hive.sh

При настройке задать пароль роли hive в PostgreSQL и повторно
ввести его для конфигурации Hive. Если роль уже существует,
использовать действующий пароль.

Конфиг с паролем создаётся в /opt/hive/conf/hive-site.xml
с правами 600 и не включается в репозиторий.

Скрипт запуска добавляет параметр Java 17 для доступа к java.nio.
В конфиге отключена проверка доступа к API уведомлений Metastore,
мешавшая запуску этой версии под пользователем team.

Логи: ~/hive-logs/metastore.log и ~/hive-logs/hiveserver2.log.

## Таблица и загрузка

Создать таблицу:

    /opt/hive/bin/beeline -u 'jdbc:hive2://127.0.0.1:10000/default' -n team -f sql/create-table.sql

Загрузить данные:

    bash scripts/load-data.sh data/events-2026-10-20.csv 2026-10-20
    bash scripts/load-data.sh data/events-2026-10-21.csv 2026-10-21

CSV содержит event_id,user_id,event_type без заголовка.
Дата передаётся отдельным аргументом и задаёт партицию event_date.

Скрипт сохраняет файл в HDFS и регистрирует партицию в Hive.
Повторная загрузка той же даты заменяет файл events.csv.

## Проверка

Подключиться:

    /opt/hive/bin/beeline -u 'jdbc:hive2://127.0.0.1:10000/default' -n team

Выполнить SQL:

    SHOW PARTITIONS hw3.events;
    SELECT * FROM hw3.events;
    SELECT * FROM hw3.events WHERE event_date='2026-10-20';

Ожидаются две партиции, четыре строки всего и две за указанную дату.
Повторить загрузку первого CSV: должно остаться четыре строки.

Для проверки нескольких клиентов открыть Beeline в двух SSH-сессиях.
Оставить оба клиента подключёнными и выполнить SELECT в каждом.
Выход из клиента: !quit.

## Результаты

Проверены загрузка двух партиций, чтение данных, повторная загрузка
без дубликатов и два одновременно подключённых клиента.
Скрипт настройки проверен на существующей базе.
Скрипт запуска проверен при работающих и остановленных сервисах.
Установка с пустых серверов целиком не проверялась.
