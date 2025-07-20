import os
import yaml
import sys # Import sys to exit script with error
from dotenv import load_dotenv

# --- Step 1: Determine the project root directory (PROJECT_ROOT_DIR) ---
# This variable will be used to find subdirectories such as 'data', 'olist_elt_pipeline', 'scripts', '.env'

project_root_dir = os.getenv("PROJECT_ROOT_DIR") # Preferably get from environment variable

if not project_root_dir:
    # If PROJECT_ROOT_DIR is not passed via environment variable (usually happens when running locally)
    # Try to infer the root directory location based on the location of this script.

    current_script_path = os.path.abspath(__file__) # Absolute path of the current script
    current_script_dir = os.path.dirname(current_script_path) # Directory containing this script

    # Check if the script is in the 'scripts' folder
    if os.path.basename(current_script_dir) == 'scripts':
        # If the path is /path/to/my_project/scripts/generate_profiles.py
        # Then the project_root_dir will be /path/to/my_project/
        project_root_dir = os.path.dirname(current_script_dir)
        print(f"[ℹ️ INFO] Inferred PROJECT_ROOT_DIR (from 'scripts' folder): {project_root_dir}")
    else:
        # If the script is not in the 'scripts' folder, assume it is in the project root
        # or the current working directory is the root. 
        project_root_dir = os.getcwd() 
        print(f"[⚠️ WARNING] PROJECT_ROOT_DIR env var not set, and script not in 'scripts' folder. Inferred project root as CWD: {project_root_dir}. Please ensure this is correct.")

# --- Step 2: Download .env file (for local development only) ---
# .env file is expected to be in the project root directory

dotenv_path = os.path.join(project_root_dir, ".env")
if os.path.exists(dotenv_path): 
    load_dotenv(dotenv_path) 
    print(f"[✅] .env file loaded from: {dotenv_path}")
else: 
    print(f"[ℹ️ INFO] No .env file found at: {dotenv_path}")

# --- Configuration variables else read from environment or default value ---

# dbt project directory name. Agreed this name is 'olist_elt_pipeline'.
DBT_FOLDER_NAME = os.getenv("DBT_FOLDER_NAME", "olist_elt_pipeline")

# Actual name of the dbt project (from dbt_project.yml 'name:' field)
DBT_PROJECT_NAME = os.getenv("DBT_PROJECT_NAME", "olist_elt_pipeline")

# Final path to the dbt project directory
# Example: /opt/airflow/olist_elt_pipeline (in Docker) or /home/user/my_project/olist_elt_pipeline (local)
dbt_project_path = os.path.join(project_root_dir, DBT_FOLDER_NAME)

# Path to the profiles.yml file
output_path = os.path.join(dbt_project_path, "profiles.yml")

# --- Load credentials for OLIST_ELT_PIPELINE profile from environment variable ---
# Get the target environment (e.g., 'dev', 'prod')
snowflake_env_target = os.getenv('SNOWFLAKE_ENV', 'dev') # Defaults to 'dev' if none
snowflake_account = os.getenv('SNOWFLAKE_ACCOUNT')
snowflake_user = os.getenv('SNOWFLAKE_USER')
snowflake_password = os.getenv('SNOWFLAKE_PASSWORD')
snowflake_role = os.getenv('SNOWFLAKE_ROLE')
snowflake_warehouse = os.getenv('SNOWFLAKE_WAREHOUSE')
snowflake_database = os.getenv('SNOWFLAKE_DATABASE')
snowflake_schema = os.getenv('SNOWFLAKE_SCHEMA')

# --- Load credentials for ELEMENTARY profile from environment variable ---
# Get the target environment (e.g., 'dev', 'prod')
elementary_env_target = os.getenv('ELEMENTARY_ENV', 'dev') # Defaults to 'dev' if none
elementary_account = os.getenv('ELEMENTARY_ACCOUNT')
elementary_user = os.getenv('ELEMENTARY_USER')
elementary_password = os.getenv('ELEMENTARY_PASSWORD')
elementary_role = os.getenv('ELEMENTARY_ROLE')
elementary_warehouse = os.getenv('ELEMENTARY_WAREHOUSE')
elementary_database = os.getenv('ELEMENTARY_DATABASE')
elementary_schema = os.getenv('ELEMENTARY_SCHEMA')

# --- Check required variables (HIGHLY RECOMMENDED) ---
# Check variables for OLIST_ELT_PIPELINE profile
required_vars_olist = { 
    'SNOWFLAKE_ACCOUNT': snowflake_account, 
    'SNOWFLAKE_USER': snowflake_user, 
    'SNOWFLAKE_PASSWORD': snowflake_password, 
    'SNOWFLAKE_WAREHOUSE': snowflake_warehouse, 
    'SNOWFLAKE_DATABASE': snowflake_database, 
    'SNOWFLAKE_SCHEMA': snowflake_schema, 
    'SNOWFLAKE_ENV': snowflake_env_target
}

missing_vars_olist = [key for key, value in required_vars_olist.items() if value is None or str(value).strip() == '']
if missing_vars_olist: 
    print(f"[❌ ERROR] Missing one or more required Snowflake environment variables: {', '.join(missing_vars_olist)}") 
    sys.exit(1)

# Check variables for ELEMENTARY profile
required_vars_elementary = {
    'ELEMENTARY_ACCOUNT': elementary_account,
    'ELEMENTARY_USER': elementary_user,
    'ELEMENTARY_PASSWORD': elementary_password,
    'ELEMENTARY_WAREHOUSE': elementary_warehouse,
    'ELEMENTARY_DATABASE': elementary_database,
    'ELEMENTARY_SCHEMA': elementary_schema,
    'ELEMENTARY_ENV': elementary_env_target
}

missing_vars_elementary = [key for key, value in required_vars_elementary.items() if value is None or str(value).strip() == '']
if missing_vars_elementary: 
    print(f"[❌ ERROR] Missing one or more required Elementary environment variables: {', '.join(missing_vars_elementary)}") 
    sys.exit(1)

# --- Build dictionary for profiles.yml ---
profiles = {
    DBT_PROJECT_NAME: {
        'target': snowflake_env_target,
        'outputs': {
            snowflake_env_target: {
                'type': 'snowflake',
                'account': snowflake_account,
                'user': snowflake_user,
                'password': snowflake_password,
                'role': snowflake_role,
                'warehouse': snowflake_warehouse,
                'database': snowflake_database,
                'schema': snowflake_schema,
                'threads': 4,
                'client_session_keep_alive': True
            }
        }
    },
    'elementary': {
        'target': elementary_env_target,
        'outputs': {
            elementary_env_target: {
                'type': 'snowflake',
                'account': elementary_account,
                'user': elementary_user,
                'password': elementary_password,
                'role': elementary_role,
                'warehouse': elementary_warehouse,
                'database': elementary_database,
                'schema': elementary_schema,
                'threads': 1,
                'client_session_keep_alive': True
            }
        }
    }
}

# --- Main Execution ---
if __name__ == "__main__":
    try:
        os.makedirs(dbt_project_path, exist_ok=True)
        with open(output_path, "w") as f:
            yaml.dump(profiles, f, default_flow_style=False, sort_keys=False)
        print(f"[✅] profiles.yml generated successfully at: {output_path}")

    except Exception as e:
        print(f"[❌ ERROR] Failed to generate profiles.yml: {e}")
        sys.exit(1)