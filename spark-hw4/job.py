from pyspark.sql import SparkSession, functions as F

SOURCE = "hdfs://team-15-nn:9000/user/team/hw3/events"
TARGET = "hw4.events_agg"

spark = (SparkSession.builder
         .appName("hw4-team15")
         .master("yarn")
         .enableHiveSupport()
         .getOrCreate())

# Данные ДЗ 3: CSV без заголовка, event_date берётся из имён папок партиций.
events = (spark.read
          .schema("event_id STRING, user_id STRING, event_type STRING")
          .csv(SOURCE))

# Преобразование типов и очистка.
events = (events
          .withColumn("event_id", F.col("event_id").cast("int"))
          .withColumn("user_id", F.col("user_id").cast("int"))
          .withColumn("event_type", F.lower(F.trim("event_type")))
          .withColumn("event_date", F.col("event_date").cast("date"))
          .dropna(subset=["event_id", "user_id", "event_date"]))

# Агрегация по дню и типу события.
agg = (events
       .groupBy("event_date", "event_type")
       .agg(F.count("*").alias("events_cnt"),
            F.countDistinct("user_id").alias("users_cnt")))

spark.sql("CREATE DATABASE IF NOT EXISTS hw4")

(agg.write
    .mode("overwrite")
    .format("parquet")
    .partitionBy("event_date")
    .saveAsTable(TARGET))

spark.sql(f"SHOW PARTITIONS {TARGET}").show(truncate=False)
spark.table(TARGET).orderBy("event_date", "event_type").show(truncate=False)

spark.stop()
