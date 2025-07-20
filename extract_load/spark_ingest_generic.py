import os
import sys
from utils.spark_session import create_spark_session

def load_env_vars_if_needed():
    """Load .env file if running locally."""
    if not os.getenv('AIRFLOW_HOME'):
        try:
            from dotenv import load_dotenv
            project_root = os.getenv("PROJECT_ROOT_DIR")
            dotenv_path = os.path.join(project_root, ".env") if project_root else ".env"

            if os.path.exists(dotenv_path):
                load_dotenv(dotenv_path)
                print(f"💡 Running locally: Loaded .env from {dotenv_path}")
            else:
                print("⚠️ No .env file found. Env vars must be set manually.")
        except ImportError:
            print("⚠️ python-dotenv not installed. Install with `pip install python-dotenv`.")
        except Exception as e:
            print(f"❌ Failed to load .env file: {e}")
    else:
        print("🚀 Running in Airflow/Docker: Env vars are expected to be pre-set.")

# Get snowflake env variables from Airflow Variables in ingest_raw_data_dag.py
def load_snowflake_config():
    """Get Snowflake connection info from env variables."""
    config = {
        "sfURL": f"{os.getenv('SNOWFLAKE_ACCOUNT')}.snowflakecomputing.com",  # Should include full domain (e.g. abc-xyz.snowflakecomputing.com)
        "sfUser": os.getenv('SNOWFLAKE_USER'), # e.g., "myuser"
        "sfPassword": os.getenv('SNOWFLAKE_PASSWORD'), # e.g., "mypassword"
        "sfDatabase": os.getenv('SNOWFLAKE_DATABASE'),  # e.g., "MY_DATABASE"
        "sfSchema": os.getenv('SNOWFLAKE_SCHEMA'), # e.g., "RAW"
        "sfWarehouse": os.getenv('SNOWFLAKE_WAREHOUSE'), # e.g., "COMPUTE_WH"
        "sfRole": os.getenv('SNOWFLAKE_ROLE'), # e.g., "TRANSFORM"
    }

    missing = [k for k, v in config.items() if not v]
    if missing:
        print(f"❌ Missing Snowflake config keys: {', '.join(missing)}")
        return None
    
    # Debug log (Optional: you can remove this block if you are absolutely sure of your setup)
    # print("🔐 Snowflake config:")
    # for k, v in config.items():
    #     print(f"  {k}: {'***' if 'Password' in k else v}")
    
    return config

def main(table_name, csv_path):
    print(f"\n🔄 [START] Ingesting: {table_name}")
    print(f"📄 CSV file: {csv_path}")

    load_env_vars_if_needed() # This function has its own internal prints for warnings/errors

    config = load_snowflake_config()
    if not config:
        return 1 # Exit if Snowflake config is missing

    spark = create_spark_session(f"Ingest_{table_name}")
    spark.sparkContext.setLogLevel("WARN") # Reduce Spark logs to WARN level

    # Read CSV
    try:
        df = spark.read.csv(csv_path, header=True)
        print("✅ Schema (inferred):")
        df.printSchema() 
    except Exception as e:
        print(f"❌ Failed to read CSV: {e}")
        spark.stop() # Ensure Spark session is stopped on error
        return 1
    # finally: # Optional clean up - can be removed if not strictly necessary
    #     spark.catalog.clearCache() 

    # # Write to Snowflake
    try:
        config["dbtable"] = table_name.upper() # Snowflake is case-sensitive and defaults to uppercase
        df.write \
            .format("snowflake") \
            .options(**config) \
            .mode("overwrite") \
            .save()
        print(f"✅ Success: Ingested '{table_name}' into Snowflake.")
    except Exception as e:
        print(f"❌ Failed to write to Snowflake: {e}")
        return 1
    finally:
        spark.stop() # Ensure Spark session is always stopped

    return 0

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("❌ Usage: python spark_ingest_generic.py <table_name> <csv_path>")
        sys.exit(1)

    # Get the first command line argument (the table name to ingest)
    table = sys.argv[1]
    # Get the second command line argument (the path to the CSV file)
    path = sys.argv[2]
    # Call the main function with these arguments to run the ingestion process
    main(table, path)
    sys.exit(main(table, path))