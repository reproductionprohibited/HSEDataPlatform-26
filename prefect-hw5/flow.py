"""Поток Prefect для запуска Spark-задачи в YARN."""

import os
import subprocess
from pathlib import Path

from prefect import flow, task

PROJECT_DIR = Path(__file__).resolve().parent
SOURCE = "/user/team/hw3/events"
TARGET = "/user/hive/warehouse/hw5.db/events_daily"


def run(*command):
    subprocess.run(command, check=True, env=os.environ.copy())


@task(name="Проверка данных в HDFS")
def check_source():
    run("hdfs", "dfs", "-test", "-e", SOURCE)
    run("hdfs", "dfs", "-ls", "-R", SOURCE)


@task(name="Проверка YARN")
def check_yarn():
    run("yarn", "node", "-list")


@task(name="Обработка данных в Spark")
def process_events():
    run("spark-submit", "--master", "yarn", "--deploy-mode", "client",
        str(PROJECT_DIR / "job.py"))


@task(name="Проверка итоговой таблицы")
def check_result():
    run("hdfs", "dfs", "-test", "-e", TARGET)
    run("hdfs", "dfs", "-ls", "-R", TARGET)
    run("spark-sql", "-e",
        "SHOW PARTITIONS hw5.events_daily; "
        "SELECT event_date, event_type, events_cnt, users_cnt "
        "FROM hw5.events_daily ORDER BY event_date, event_type;")


@flow(name="hw5-team15-prefect", log_prints=True)
def hw5_flow():
    check_source()
    check_yarn()
    process_events()
    check_result()


if __name__ == "__main__":
    hw5_flow()
