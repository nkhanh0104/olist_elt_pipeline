from pyspark.sql import SparkSession

def create_spark_session(
    app_name: str = None,
    executor_memory: str = "2g",
    shuffle_partitions: str = "8"
) -> SparkSession:
    """
    Create and return a SparkSession configured for Snowflake integration.
    This version ensures the Snowflake Spark Connector is loaded.
    
    Args:
        app_name (str): Optional name of the Spark app.
        executor_memory (str): Executor memory allocation (e.g., '2g').
        shuffle_partitions (str): Number of shuffle partitions for Spark.
    Returns:
        SparkSession: Configured Spark session.
    """
    builder = SparkSession.builder
    if app_name:
        builder = builder.appName(app_name)

    spark = (
        builder
        .config("spark.jars.packages", "net.snowflake:spark-snowflake_2.12:2.16.0-spark_3.4")
        .config("spark.executor.memory", executor_memory)
        .config("spark.sql.shuffle.partitions", shuffle_partitions)
        .getOrCreate()
    )
    
    return spark