"""Агрегация событий из HDFS в таблицу Hive через Spark on YARN."""

from pyspark.sql import SparkSession, functions as F

SOURCE = "hdfs://team-15-nn:9000/user/team/hw3/events"
TARGET = "hw5.events_daily"


def main():
    spark = (SparkSession.builder
             .appName("hw5-team15")
             .master("yarn")
             .enableHiveSupport()
             .getOrCreate())
    try:
        # event_date Spark получает из каталогов event_date=YYYY-MM-DD.
        events = (spark.read
                  .option("basePath", SOURCE)
                  .schema("event_id STRING, user_id STRING, event_type STRING")
                  .csv(SOURCE))

        cleaned = (events
                   .withColumn("event_id", F.col("event_id").cast("int"))
                   .withColumn("user_id", F.col("user_id").cast("int"))
                   .withColumn("event_type", F.lower(F.trim("event_type")))
                   .withColumn("event_date", F.col("event_date").cast("date"))
                   .dropna(subset=["event_id", "user_id", "event_date", "event_type"])
                   .filter(F.col("event_type") != ""))

        if cleaned.limit(1).count() == 0:
            raise ValueError("В HDFS нет корректных событий для обработки")

        daily = (cleaned
                 .groupBy("event_date", "event_type")
                 .agg(F.count("*").alias("events_cnt"),
                      F.countDistinct("user_id").alias("users_cnt")))

        spark.sql("CREATE DATABASE IF NOT EXISTS hw5")
        (daily.write
         .mode("overwrite")
         .format("parquet")
         .partitionBy("event_date")
         .saveAsTable(TARGET))

        spark.table(TARGET).orderBy("event_date", "event_type").show(truncate=False)
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
