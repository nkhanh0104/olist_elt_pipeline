from airflow.decorators import dag
from airflow.operators.bash import BashOperator
from airflow.models import Variable
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

# Get snowflake env variables from Airflow Variables
snowflake_env_vars = {
    'SNOWFLAKE_ACCOUNT': Variable.get('SNOWFLAKE_ACCOUNT'),
    'SNOWFLAKE_USER': Variable.get('SNOWFLAKE_USER'),
    'SNOWFLAKE_PASSWORD': Variable.get('SNOWFLAKE_PASSWORD'),
    'SNOWFLAKE_ROLE': Variable.get('SNOWFLAKE_ROLE'),
    'SNOWFLAKE_WAREHOUSE': Variable.get('SNOWFLAKE_WAREHOUSE'),
    'SNOWFLAKE_DATABASE': Variable.get('SNOWFLAKE_DATABASE'),
    'SNOWFLAKE_SCHEMA': Variable.get('SNOWFLAKE_SCHEMA_RAW'),
    'SNOWFLAKE_ENV': Variable.get('SNOWFLAKE_ENV')
}

# Define DAG using decorator style (AIP-48)
@dag(
    dag_id='ingest_all_raw_data_dag',
    default_args=default_args,
    description='Ingest raw CSV data into Snowflake using PySpark',
    schedule_interval='0 4 * * *',  # Run 4 AM everyday
    start_date=datetime(2025, 7, 1),
    catchup=False,
    tags=['ingest', 'pyspark', 'snowflake']
)

def ingest_all_raw_data_pipeline():
    """
    This is the main pipeline definition function of the DAG according to the AIP-48 standard.
    Tasks are defined by directly instantiating the BashOperator.
    """

    # Instantiate BashOperator directly.
    # In a function decorated with @dag, operators instantiated this way
    # will automatically be registered as tasks in the DAG.
    # Note: If use bash_command='/opt/airflow/ingest_all.sh ', 
    #       add a space after .sh to avoid Airflow trying to treat it as a Jinja template.
    # set -ex # Print the command and exit if there is an error
    ingest_all_data = BashOperator(
        task_id='ingest_all_raw_data',
        bash_command=f"""
            set -ex
            /opt/airflow/ingest_all.sh 
        """,
        env=snowflake_env_vars
    )

    ingest_all_data

# Initialize the DAG by calling the decorated pipeline function
ingest_all_raw_data_dag = ingest_all_raw_data_pipeline()