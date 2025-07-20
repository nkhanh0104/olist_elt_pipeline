from airflow.decorators import dag
from airflow.operators.bash import BashOperator
from airflow.models import Variable
from datetime import datetime, timedelta
import json
import os

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

# Get PROJECT_ROOT_DIR from Airflow Variables
PROJECT_ROOT_DIR_AIRFLOW_VAR = Variable.get('PROJECT_ROOT_DIR_AIRFLOW_VAR', default_var='/opt/airflow') 

# Path to dbt and edr executables within the container
DBT_CLI_PATH = '/home/airflow/.local/bin/dbt'
EDR_CLI_PATH = '/home/airflow/.local/bin/edr'

# Get dbt env variables from Airflow Variables
dbt_env = {
    # Add neccessary variables for generate_profiles.py
    'SNOWFLAKE_ACCOUNT': Variable.get('SNOWFLAKE_ACCOUNT'),
    'SNOWFLAKE_USER': Variable.get('SNOWFLAKE_USER'),
    'SNOWFLAKE_PASSWORD': Variable.get('SNOWFLAKE_PASSWORD'),
    'SNOWFLAKE_ROLE': Variable.get('SNOWFLAKE_ROLE'),
    'SNOWFLAKE_WAREHOUSE': Variable.get('SNOWFLAKE_WAREHOUSE'),
    'SNOWFLAKE_DATABASE': Variable.get('SNOWFLAKE_DATABASE'),
    'SNOWFLAKE_SCHEMA': Variable.get('SNOWFLAKE_SCHEMA_RAW'),
    'SNOWFLAKE_ENV': Variable.get('SNOWFLAKE_ENV'),
    'PROJECT_ROOT_DIR': PROJECT_ROOT_DIR_AIRFLOW_VAR, # /opt/airflow
    'DBT_PROJECT_NAME': Variable.get('DBT_PROJECT_NAME'), # Dbt project name (name) from dbt_project.yml
    'DBT_FOLDER_NAME': Variable.get('DBT_FOLDER_NAME'), # Dbt folder name is consistent
    'ELEMENTARY_ACCOUNT': Variable.get('ELEMENTARY_ACCOUNT'),
    'ELEMENTARY_USER': Variable.get('ELEMENTARY_USER'),
    'ELEMENTARY_PASSWORD': Variable.get('ELEMENTARY_PASSWORD'),
    'ELEMENTARY_ROLE': Variable.get('ELEMENTARY_ROLE'),
    'ELEMENTARY_WAREHOUSE': Variable.get('ELEMENTARY_WAREHOUSE'),
    'ELEMENTARY_DATABASE': Variable.get('ELEMENTARY_DATABASE'),
    'ELEMENTARY_SCHEMA': Variable.get('ELEMENTARY_SCHEMA'),
    'ELEMENTARY_ENV': Variable.get('ELEMENTARY_ENV')
}

# Path to the generate_profiles.py script in the container
GENERATE_PROFILES_SCRIPT_PATH = os.path.join(PROJECT_ROOT_DIR_AIRFLOW_VAR, 'scripts', 'generate_profiles.py')

# The path is consistent to the dbt project directory in the container
DBT_PROJECT_ROOT_IN_CONTAINER = os.path.join(PROJECT_ROOT_DIR_AIRFLOW_VAR, Variable.get('DBT_FOLDER_NAME'))


# Optional vars for mart layer (get from Airflow Variables, fallback to None)
def get_optional_var(name):
    try:
        return Variable.get(name)
    except KeyError:
        return None
    
# Load mart parameters from Airflow Variables
dbt_vars = {}
for key in ['DBT_VAR_YEAR', 'DBT_VAR_MONTH', 'DBT_VAR_QUARTER', 'DBT_VAR_DATE']:
    val = get_optional_var(key)
    # Only handle if value is not None and not string 'null' or string ''
    if val is not None and str(val).lower() != 'null' and str(val).strip() != '':
        try:
            # Try parse to int
            dbt_vars[key.replace('DBT_VAR_', '').lower()] = int(val)
        except ValueError:
            # Handle invalid value
            print(f"Warning: Airflow variable '{key}' is invalid: '{val}'")
            pass # Pass this variable if invalid number

vars_str = json.dumps(dbt_vars)

# Define DAG using decorator style (AIP-48)
@dag(
    dag_id='dbt_full_pipeline_dag',
    default_args=default_args,
    description='Run full DBT pipeline with Elementary',
    schedule_interval='30 4 * * *',  # Run at 4:30 AM everyday
    start_date=datetime(2025, 7, 1),
    catchup=False,
    tags=['dbt', 'elt', 'snowflake']
)

def dbt_full_pipeline_dag_pipeline():
    """
    This is the main pipeline definition function of the DAG according to the AIP-48 standard.
    Tasks are defined by directly instantiating the BashOperator.
    """

    # Task to create profiles.yml
    generate_dbt_profiles = BashOperator(
        task_id='generate_dbt_profiles',
        bash_command=f"""
            set -ex
            python {GENERATE_PROFILES_SCRIPT_PATH} 2>&1
        """,
        env=dbt_env # Script will read env vars from dbt_env
    )

    # Task dbt debug
    dbt_debug = BashOperator(
        task_id='dbt_debug',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} debug 2>&1
        """,
        env=dbt_env
    )

    # Task dbt deps
    dbt_deps = BashOperator(
        task_id='dbt_deps',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} deps 2>&1
        """,
        env=dbt_env
    )

    # Task dbt seed
    dbt_seed = BashOperator(
        task_id='dbt_seed',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} seed 2>&1
        """,
        env=dbt_env
    )

    # Task dbt run
    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} run --vars '{vars_str}' 2>&1
        """,
        env=dbt_env
    )

    # Task dbt test
    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} test 2>&1
        """,
        env=dbt_env
    )

    # Task dbt docs generate
    dbt_docs_generate = BashOperator(
        task_id='dbt_docs_generate',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {DBT_CLI_PATH} docs generate 2>&1
        """,
        env=dbt_env
    )

    # Task elementary run report
    elementary_run_report = BashOperator(
        task_id='elementary_run_report',
        bash_command=f"""
            set -ex
            cd {DBT_PROJECT_ROOT_IN_CONTAINER} && \\
            {EDR_CLI_PATH} report --profiles-dir {DBT_PROJECT_ROOT_IN_CONTAINER} --profile-target {dbt_env['ELEMENTARY_ENV']} 2>&1
        """,
        env=dbt_env
    )

    # Define workflow using operator >>
    generate_dbt_profiles >> dbt_debug >> dbt_deps >> dbt_seed >> dbt_run >> dbt_test >> dbt_docs_generate >> elementary_run_report

# Initialize the DAG by calling the decorated pipeline function
dbt_full_pipeline_dag = dbt_full_pipeline_dag_pipeline()
